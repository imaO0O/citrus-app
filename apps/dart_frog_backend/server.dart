import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

PostgreSQLConnection? _db;
const _jwtSecret = 'citrus-app-secret-key-change-in-production';

// Cloudinary конфигурация
const _cloudinaryCloudName = 'dgeoniumv';
const _cloudinaryApiKey = '826774537124372';
const _cloudinaryApiSecret = 'dyJlkMFKHKKFJcnDCbDOPfj7fc0';
const _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/dgeoniumv/image/upload';

class _AuthContext {
  String? userId;
}

String? _extractToken(RequestContext context) {
  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7);
}

String _hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Future<Response> _handleRequest(RequestContext context) async {
  final authContext = _AuthContext();

  // Инициализация БД при первом запросе
  if (_db == null || _db!.isClosed) {
    try {
      _db = PostgreSQLConnection(
        'localhost',
        5432,
        'citrus',
        username: 'citrus',
        password: 'citrus123',
      );
      await _db!.open();
      print('Database connected!');
    } catch (e) {
      return Response(
        statusCode: 500,
        body: 'Database connection failed: $e',
      );
    }
  }

  final path = context.request.uri.path;
  final method = context.request.method;

  // Auth endpoints
  if (path == '/auth/register' && method == HttpMethod.post) {
    return _register(context);
  }
  if (path == '/auth/login' && method == HttpMethod.post) {
    return _login(context);
  }

  // GET /themes - получить список тем
  if (path == '/themes' && method == HttpMethod.get) {
    return _getThemes(context);
  }

  // PUT /user/theme - обновить тему пользователя
  if (path == '/user/theme' && method == HttpMethod.put) {
    return _updateUserTheme(context);
  }

  // Sleep endpoints (требуют авторизации)
  if (path.startsWith('/sleep/')) {
    final token = _extractToken(context);
    if (token == null) {
      print('Sleep endpoint: токен не найден');
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
      print('Sleep endpoint: токен проверен, user_id=${authContext.userId}');
    } catch (e) {
      print('Sleep endpoint: ошибка проверки токена: $e');
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /sleep/records
  if (path == '/sleep/records' && method == HttpMethod.get) {
    return _getSleepRecords(context, authContext);
  }

  // POST /sleep/records
  if (path == '/sleep/records' && method == HttpMethod.post) {
    return _createSleepRecord(context, authContext);
  }

  // PUT /sleep/records/{id}
  if (path.startsWith('/sleep/records/') && method == HttpMethod.put) {
    final id = path.substring('/sleep/records/'.length);
    return _updateSleepRecord(context, authContext, id);
  }

  // DELETE /sleep/records/{id}
  if (path.startsWith('/sleep/records/') && method == HttpMethod.delete) {
    final id = path.substring('/sleep/records/'.length);
    return _deleteSleepRecord(context, authContext, id);
  }

  // Calendar endpoints (требуют авторизации)
  if (path.startsWith('/calendar/')) {
    final token = _extractToken(context);
    if (token == null) {
      print('Calendar endpoint: токен не найден');
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
      print('Calendar endpoint: токен проверен, user_id=${authContext.userId}');
    } catch (e) {
      print('Calendar endpoint: ошибка проверки токена: $e');
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /calendar/events
  if (path == '/calendar/events' && method == HttpMethod.get) {
    return _getEvents(context, authContext);
  }
  
  // POST /calendar/events
  if (path == '/calendar/events' && method == HttpMethod.post) {
    return _createEvent(context, authContext);
  }
  
  // PUT /calendar/events/{id}
  if (path.startsWith('/calendar/events/') && method == HttpMethod.put) {
    final id = path.substring('/calendar/events/'.length);
    return _updateEvent(context, authContext, id);
  }
  
  // DELETE /calendar/events/{id}
  if (path.startsWith('/calendar/events/') && method == HttpMethod.delete) {
    final id = path.substring('/calendar/events/'.length);
    return _deleteEvent(context, authContext, id);
  }

  // Mood endpoints (требуют авторизации)
  if (path.startsWith('/mood/')) {
    final token = _extractToken(context);
    if (token == null) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /mood/records
  if (path == '/mood/records' && method == HttpMethod.get) {
    return _getMoodRecords(context, authContext);
  }

  // POST /mood/records
  if (path == '/mood/records' && method == HttpMethod.post) {
    return _createMoodRecord(context, authContext);
  }

  // PUT /mood/records/{id}
  if (path.startsWith('/mood/records/') && method == HttpMethod.put) {
    final id = path.substring('/mood/records/'.length);
    return _updateMoodRecord(context, authContext, id);
  }

  // DELETE /mood/records/{id}
  if (path.startsWith('/mood/records/') && method == HttpMethod.delete) {
    final id = path.substring('/mood/records/'.length);
    return _deleteMoodRecord(context, authContext, id);
  }

  // Psychological tests endpoints (требуют авторизации для сохранения результатов)
  if (path.startsWith('/tests')) {
    // GET /tests и GET /tests/{id} - публичные, без авторизации
    if (method == HttpMethod.get) {
      if (path == '/tests' || path == '/tests/') {
        return _getAvailableTests(context);
      }
      if (path.startsWith('/tests/') && !path.contains('/submit') && !path.contains('/results')) {
        final testId = path.split('/')[2];
        return _getTest(context, testId);
      }
    }

    // Остальные методы требуют авторизации
    final token = _extractToken(context);
    if (token == null) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /tests - список доступных тестов
  if (path == '/tests' && method == HttpMethod.get) {
    return _getAvailableTests(context);
  }

  // GET /tests/{testId} - получить тест с вопросами
  if (path.startsWith('/tests/') && method == HttpMethod.get && !path.contains('/submit') && !path.contains('/results')) {
    final testId = path.split('/')[2];
    return _getTest(context, testId);
  }

  // POST /tests/{testId}/submit - отправить ответы
  if (path.contains('/submit') && method == HttpMethod.post) {
    final parts = path.split('/');
    final testId = parts[2];
    return _submitTest(context, authContext, testId);
  }

  // GET /tests/results - история результатов
  if ((path == '/tests/results' || path == '/tests/results/') && method == HttpMethod.get) {
    return _getTestResults(context, authContext);
  }

  // GET /tests/results/{testId} - результаты конкретного теста
  if (path.startsWith('/tests/results/') && method == HttpMethod.get && !path.contains('/submit')) {
    final testId = path.split('/')[3];
    return _getTestResult(context, authContext, testId);
  }

  // Diary endpoints (требуют авторизации)
  if (path.startsWith('/diary/')) {
    final token = _extractToken(context);
    if (token == null) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /diary/entries
  if (path == '/diary/entries' && method == HttpMethod.get) {
    return _getDiaryEntries(context, authContext);
  }

  // POST /diary/entries
  if (path == '/diary/entries' && method == HttpMethod.post) {
    return _createDiaryEntry(context, authContext);
  }

  // PUT /diary/entries/{id}
  if (path.startsWith('/diary/entries/') && method == HttpMethod.put) {
    final id = path.substring('/diary/entries/'.length);
    return _updateDiaryEntry(context, authContext, id);
  }

  // DELETE /diary/entries/{id}
  if (path.startsWith('/diary/entries/') && method == HttpMethod.delete) {
    final id = path.substring('/diary/entries/'.length);
    return _deleteDiaryEntry(context, authContext, id);
  }

  // Trusted contacts endpoints (требуют авторизации)
  if (path.startsWith('/trusted-contacts')) {
    final token = _extractToken(context);
    if (token == null) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /trusted-contacts
  if (path == '/trusted-contacts' && method == HttpMethod.get) {
    return _getTrustedContacts(context, authContext);
  }

  // POST /trusted-contacts
  if (path == '/trusted-contacts' && method == HttpMethod.post) {
    return _createTrustedContact(context, authContext);
  }

  // PUT /trusted-contacts/{id}
  if (path.startsWith('/trusted-contacts/') && method == HttpMethod.put) {
    final id = path.substring('/trusted-contacts/'.length);
    return _updateTrustedContact(context, authContext, id);
  }

  // DELETE /trusted-contacts/{id}
  if (path.startsWith('/trusted-contacts/') && method == HttpMethod.delete) {
    final id = path.substring('/trusted-contacts/'.length);
    return _deleteTrustedContact(context, authContext, id);
  }

  // Photos endpoints (требуют авторизации)
  if (path.startsWith('/photos')) {
    final token = _extractToken(context);
    if (token == null) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      authContext.userId = jwt.payload['user_id'] as String;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /photos
  if (path == '/photos' && method == HttpMethod.get) {
    return _getPhotos(context, authContext);
  }

  // POST /photos
  if (path == '/photos' && method == HttpMethod.post) {
    return _createPhoto(context, authContext);
  }

  // PATCH /photos/{id}/favorite
  if (path.startsWith('/photos/') && path.endsWith('/favorite') && method == HttpMethod.patch) {
    final id = path.substring('/photos/'.length, path.length - '/favorite'.length);
    return _togglePhotoFavorite(context, authContext, id);
  }

  // DELETE /photos/{id}
  if (path.startsWith('/photos/') && method == HttpMethod.delete) {
    final id = path.substring('/photos/'.length);
    return _deletePhoto(context, authContext, id);
  }

  return Response.json(body: {'message': 'Citrus API'});
}

Future<Response> _register(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final name = body['name'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'email and password are required');
    }

    if (password.length < 6) {
      return Response(statusCode: 400, body: 'Password must be at least 6 characters');
    }

    // Проверяем существование пользователя
    final existing = await _db!.query(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (existing.isNotEmpty) {
      return Response(statusCode: 409, body: 'User already exists');
    }

    final userId = const Uuid().v4();
    final passwordHash = _hashPassword(password);
    final nameSql = name != null && name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';

    await _db!.query(
      "INSERT INTO users (id, email, password_hash, name, theme_id) VALUES ('$userId', '$email', '$passwordHash', $nameSql, '00000000-0000-0000-0000-000000000001')",
    );

    // Создаем JWT токен
    final token = JWT(
      {'user_id': userId, 'email': email},
      issuer: 'citrus-app',
    ).sign(SecretKey(_jwtSecret));

    return Response.json(
      statusCode: 201,
      body: {
        'id': userId,
        'email': email,
        'name': name,
        'theme_id': '00000000-0000-0000-0000-000000000001',
        'token': token,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _login(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'email and password are required');
    }

    final results = await _db!.query(
      "SELECT id, email, name, theme_id, password_hash FROM users WHERE email = '$email'",
    );

    if (results.isEmpty) {
      return Response(statusCode: 401, body: 'Invalid credentials');
    }

    final row = results.first;
    final storedHash = row[4] as String;
    final inputHash = _hashPassword(password);

    if (storedHash != inputHash) {
      return Response(statusCode: 401, body: 'Invalid credentials');
    }

    final userId = row[0] as String;
    final token = JWT(
      {'user_id': userId, 'email': email},
      issuer: 'citrus-app',
    ).sign(SecretKey(_jwtSecret));

    return Response.json(body: {
      'id': userId,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'token': token,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _getEvents(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;

  print('_getEvents: запрос для userId=$userId');

  if (userId == null) {
    print('_getEvents: userId is null, возвращаем 401');
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _db!.query(
      "SELECT id, user_id, title, description, event_date, "
      "start_time::text as start_time, "
      "end_time::text as end_time, "
      "notification_enabled "
      "FROM calendar_events "
      "WHERE user_id = '$userId' "
      "ORDER BY event_date DESC, start_time",
    );

    print('_getEvents: найдено ${results.length} событий');

    final events = results.map((row) {
      // UUID из PostgreSQL возвращается как байты - нужно конвертировать
      final id = row[0];
      final userId = row[1];
      final title = row[2];
      final description = row[3];
      final eventDate = row[4];
      final startTime = row[5];
      final endTime = row[6];
      final notificationEnabled = row[7];

      // Преобразуем startTime и endTime в строку
      String? startTimeStr;
      if (startTime != null) {
        startTimeStr = startTime is String ? startTime : startTime.toString();
      }
      
      String? endTimeStr;
      if (endTime != null) {
        endTimeStr = endTime is String ? endTime : endTime.toString();
      }

      return {
        'id': id is String ? id : Uuid.unparse(id as Uint8List),
        'user_id': userId is String ? userId : Uuid.unparse(userId as Uint8List),
        'title': title is String ? title : '',
        'description': description is String ? description : null,
        'event_date': (eventDate as DateTime).toIso8601String(),
        'start_time': startTimeStr,
        'end_time': endTimeStr,
        'notification_enabled': notificationEnabled as bool,
      };
    }).toList();

    return Response.json(body: events);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createEvent(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final body = await context.request.json();
  
  final title = body['title'] as String?;
  final eventDate = body['event_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (title == null || eventDate == null) {
    return Response(statusCode: 400, body: 'title and event_date are required');
  }

  try {
    final eventId = const Uuid().v4();
    final description = body['description'] as String? ?? '';
    final startTime = body['start_time'] as String?;
    final endTime = body['end_time'] as String?;
    final notificationEnabled = body['notification_enabled'] as bool? ?? true;

    final startTimeSql = startTime != null ? "'$startTime'" : 'NULL';
    final endTimeSql = endTime != null ? "'$endTime'" : 'NULL';
    final descriptionSql = description.isNotEmpty ? "'${description.replaceAll("'", "''")}'" : 'NULL';

    await _db!.query(
      "INSERT INTO calendar_events (id, user_id, title, description, event_date, start_time, end_time, notification_enabled) "
      "VALUES ('$eventId', '$userId', '${title.replaceAll("'", "''")}', $descriptionSql, '$eventDate', $startTimeSql, $endTimeSql, $notificationEnabled)",
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': eventId,
        'user_id': userId,
        'title': title,
        'description': description,
        'event_date': eventDate,
        'start_time': startTime,
        'end_time': endTime,
        'notification_enabled': notificationEnabled,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateEvent(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final title = body['title'] as String?;
  final eventDate = body['event_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (title == null || eventDate == null) {
    return Response(statusCode: 400, body: 'title and event_date are required');
  }

  try {
    final description = body['description'] as String? ?? '';
    final startTime = body['start_time'] as String?;
    final endTime = body['end_time'] as String?;
    final notificationEnabled = body['notification_enabled'] as bool? ?? true;

    final startTimeSql = startTime != null ? "'$startTime'" : 'NULL';
    final endTimeSql = endTime != null ? "'$endTime'" : 'NULL';
    final descriptionSql = description.isNotEmpty ? "'${description.replaceAll("'", "''")}'" : 'NULL';

    // Проверяем, что событие принадлежит пользователю
    final checkResults = await _db!.query(
      "SELECT id FROM calendar_events WHERE id = '$id' AND user_id = '$userId'",
    );

    if (checkResults.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    final results = await _db!.query(
      "UPDATE calendar_events "
      "SET title = '${title.replaceAll("'", "''")}', description = $descriptionSql, event_date = '$eventDate', "
      "start_time = $startTimeSql, end_time = $endTimeSql, notification_enabled = $notificationEnabled "
      "WHERE id = '$id' AND user_id = '$userId' "
      "RETURNING id, user_id, title, description, event_date, start_time, end_time, notification_enabled",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    final row = results.first;
    return Response.json(body: {
      'id': row[0] as String,
      'user_id': row[1] as String,
      'title': row[2] as String,
      'description': row[3] as String?,
      'event_date': (row[4] as DateTime).toIso8601String(),
      'start_time': row[5] as String?,
      'end_time': row[6] as String?,
      'notification_enabled': row[7] as bool,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteEvent(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    // Проверяем и удаляем только свои события
    final results = await _db!.query(
      "DELETE FROM calendar_events WHERE id = '$id' AND user_id = '$userId' RETURNING id",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить список всех тем
Future<Response> _getThemes(RequestContext context) async {
  try {
    final results = await _db!.query(
      "SELECT id, name, is_dark, primary_color, accent_color FROM themes ORDER BY id",
    );

    final themes = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'name': row[1] as String,
        'is_dark': row[2] as bool,
        'primary_color': row[3] as String,
        'accent_color': row[4] as String,
      };
    }).toList();

    return Response.json(body: themes);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить тему пользователя
Future<Response> _updateUserTheme(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;
    final body = await context.request.json();
    final themeId = body['theme_id'] as String?;

    if (themeId == null) {
      return Response(statusCode: 400, body: 'theme_id is required');
    }

    await _db!.query(
      "UPDATE users SET theme_id = '$themeId' WHERE id = '$userId'",
    );

    return Response.json(body: {'theme_id': themeId});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить записи сна
Future<Response> _getSleepRecords(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final startDate = context.request.uri.queryParameters['start_date'] ?? '2020-01-01';
  final endDate = context.request.uri.queryParameters['end_date'] ?? '2030-12-31';

  print('_getSleepRecords: запрос для userId=$userId');

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _db!.query(
      "SELECT id, user_id, sleep_date, "
      "bed_time::text as bed_time, "
      "wake_time::text as wake_time, "
      "quality "
      "FROM sleep_records "
      "WHERE user_id = '$userId' "
      "AND sleep_date >= '$startDate' "
      "AND sleep_date <= '$endDate' "
      "ORDER BY sleep_date DESC",
    );

    print('_getSleepRecords: найдено ${results.length} записей');

    final records = results.map((row) {
      final id = row[0];
      final userId = row[1];
      final sleepDate = row[2];
      final bedTime = row[3];
      final wakeTime = row[4];
      final quality = row[5];

      print('_getSleepRecords: bedTime тип=${bedTime.runtimeType}, значение=$bedTime');
      print('_getSleepRecords: wakeTime тип=${wakeTime.runtimeType}, значение=$wakeTime');

      // Преобразуем bed_time и wake_time из байт в строку
      String? bedTimeStr;
      if (bedTime != null) {
        bedTimeStr = bedTime is String ? bedTime : String.fromCharCodes(bedTime as List<int>);
        print('_getSleepRecords: bedTimeStr=$bedTimeStr');
      }

      String? wakeTimeStr;
      if (wakeTime != null) {
        wakeTimeStr = wakeTime is String ? wakeTime : String.fromCharCodes(wakeTime as List<int>);
        print('_getSleepRecords: wakeTimeStr=$wakeTimeStr');
      }

      return {
        'id': id is String ? id : Uuid.unparse(id as Uint8List),
        'user_id': userId is String ? userId : Uuid.unparse(userId as Uint8List),
        'sleep_date': (sleepDate as DateTime).toIso8601String().split('T').first,
        'bed_time': bedTimeStr != null && bedTimeStr.isNotEmpty ? bedTimeStr : null,
        'wake_time': wakeTimeStr != null && wakeTimeStr.isNotEmpty ? wakeTimeStr : null,
        'quality': quality is int ? quality : null,
      };
    }).toList();

    print('_getSleepRecords: возвращаем ${records.length} записей');
    for (final rec in records) {
      print('_getSleepRecords: запись bed_time=${rec['bed_time']}, wake_time=${rec['wake_time']}');
    }

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Создать запись сна
Future<Response> _createSleepRecord(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final sleepDate = body['sleep_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (sleepDate == null) {
    return Response(statusCode: 400, body: 'sleep_date is required');
  }

  try {
    final recordId = const Uuid().v4();
    final bedTime = body['bed_time'] as String?;
    final wakeTime = body['wake_time'] as String?;
    final quality = body['quality'] as int?;

    final bedTimeSql = (bedTime != null && bedTime.isNotEmpty) ? "'$bedTime'" : 'NULL';
    final wakeTimeSql = (wakeTime != null && wakeTime.isNotEmpty) ? "'$wakeTime'" : 'NULL';
    final qualitySql = quality != null ? quality.toString() : 'NULL';

    await _db!.query(
      "INSERT INTO sleep_records (id, user_id, sleep_date, bed_time, wake_time, quality) "
      "VALUES ('$recordId', '$userId', '$sleepDate', $bedTimeSql, $wakeTimeSql, $qualitySql)",
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': recordId,
        'user_id': userId,
        'sleep_date': sleepDate,
        'bed_time': bedTime,
        'wake_time': wakeTime,
        'quality': quality,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить запись сна
Future<Response> _updateSleepRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final sleepDate = body['sleep_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (sleepDate == null) {
    return Response(statusCode: 400, body: 'sleep_date is required');
  }

  try {
    final bedTime = body['bed_time'] as String?;
    final wakeTime = body['wake_time'] as String?;
    final quality = body['quality'] as int?;

    final bedTimeSql = (bedTime != null && bedTime.isNotEmpty) ? "'$bedTime'" : 'NULL';
    final wakeTimeSql = (wakeTime != null && wakeTime.isNotEmpty) ? "'$wakeTime'" : 'NULL';
    final qualitySql = quality != null ? quality.toString() : 'NULL';

    // Проверяем, что запись принадлежит пользователю
    final checkResults = await _db!.query(
      "SELECT id FROM sleep_records WHERE id = '$id' AND user_id = '$userId'",
    );

    if (checkResults.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    final results = await _db!.query(
      "UPDATE sleep_records "
      "SET sleep_date = '$sleepDate', bed_time = $bedTimeSql, wake_time = $wakeTimeSql, quality = $qualitySql "
      "WHERE id = '$id' AND user_id = '$userId' "
      "RETURNING id, user_id, sleep_date, bed_time, wake_time, quality",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    final row = results.first;
    
    // Преобразуем bed_time и wake_time из байт в строку
    String? bedTimeResult;
    if (row[3] != null) {
      bedTimeResult = row[3] is String ? row[3] : String.fromCharCodes(row[3] as List<int>);
    }
    
    String? wakeTimeResult;
    if (row[4] != null) {
      wakeTimeResult = row[4] is String ? row[4] : String.fromCharCodes(row[4] as List<int>);
    }
    
    return Response.json(body: {
      'id': row[0] as String,
      'user_id': row[1] as String,
      'sleep_date': (row[2] as DateTime).toIso8601String().split('T').first,
      'bed_time': bedTimeResult != null && bedTimeResult.isNotEmpty ? bedTimeResult : null,
      'wake_time': wakeTimeResult != null && wakeTimeResult.isNotEmpty ? wakeTimeResult : null,
      'quality': row[5] as int?,
    });
  } catch (e) {
    print('_updateSleepRecord: ошибка: $e');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Удалить запись сна
Future<Response> _deleteSleepRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _db!.query(
      "DELETE FROM sleep_records WHERE id = '$id' AND user_id = '$userId' RETURNING id",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== MOOD ENDPOINTS ====================

Future<Response> _getMoodRecords(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final query = context.request.uri.queryParameters;
    final startDate = query['start_date'];
    final endDate = query['end_date'];

    String whereClause = "WHERE user_id = '$userId'";
    if (startDate != null) whereClause += " AND DATE(recorded_at) >= '$startDate'";
    if (endDate != null) whereClause += " AND DATE(recorded_at) <= '$endDate'";

    final results = await _db!.query(
      "SELECT id, user_id, mood_value, recorded_at::text "
      "FROM mood_entries $whereClause ORDER BY recorded_at DESC",
    );

    final records = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'mood_id': row[2] as int,
      'mood_date': row[3],
    }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createMoodRecord(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final moodId = body['mood_id'] as int?;
    final moodDate = body['mood_date'] as String?;
    final note = body['note'] as String?;

    if (moodId == null) {
      return Response(statusCode: 400, body: 'mood_id is required');
    }

    final recordId = const Uuid().v4();
    final timeOfDay = moodDate != null ? _getTimeOfDay(moodDate) : null;
    final timeOfDaySql = timeOfDay != null ? "'$timeOfDay'" : 'NULL';

    final sql = moodDate != null
        ? "INSERT INTO mood_entries (id, user_id, mood_value, time_of_day, recorded_at) "
          "VALUES ('$recordId', '$userId', $moodId, $timeOfDaySql, '$moodDate')"
        : "INSERT INTO mood_entries (id, user_id, mood_value, time_of_day) "
          "VALUES ('$recordId', '$userId', $moodId, $timeOfDaySql)";

    print('mood create SQL: $sql');

    await _db!.query(sql);

    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'user_id': userId,
      'mood_id': moodId,
      'mood_date': moodDate ?? DateTime.now().toIso8601String(),
      'note': note,
    });
  } catch (e, stackTrace) {
    print('mood create error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateMoodRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final moodId = body['mood_id'] as int?;

    if (moodId == null) {
      return Response(statusCode: 400, body: 'mood_id is required');
    }

    await _db!.query(
      "UPDATE mood_entries SET mood_value = $moodId "
      "WHERE id = '$id' AND user_id = '$userId'",
    );

    return Response.json(body: {'id': id, 'mood_id': moodId});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteMoodRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    await _db!.query("DELETE FROM mood_entries WHERE id = '$id' AND user_id = '$userId'");
    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

String _getTimeOfDay(String isoDate) {
  final dt = DateTime.parse(isoDate);
  if (dt.hour < 12) return 'morning';
  if (dt.hour < 18) return 'afternoon';
  return 'evening';
}

// ==================== DIARY ENDPOINTS ====================

Future<Response> _getDiaryEntries(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final query = context.request.uri.queryParameters;
    final startDate = query['start_date'];
    final endDate = query['end_date'];
    final search = query['search'];

    String whereClause = "WHERE user_id = '$userId'";
    if (startDate != null) whereClause += " AND entry_date >= '$startDate'";
    if (endDate != null) whereClause += " AND entry_date <= '$endDate'";
    if (search != null && search.isNotEmpty) {
      whereClause += " AND (content ILIKE '%$search%' OR title ILIKE '%$search%')";
    }

    final results = await _db!.query(
      "SELECT id, user_id, content, mood_value, entry_date::text, created_at::text "
      "FROM diary_entries $whereClause ORDER BY entry_date DESC, created_at DESC",
    );

    final entries = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'content': row[2] as String?,
      'mood_value': row[3] as int?,
      'entry_date': row[4],
      'created_at': row[5],
      'title': (row[2] as String?)?.substring(0, row[2].toString().length > 50 ? 50 : null) ?? 'Без заголовка',
    }).toList();

    return Response.json(body: entries);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createDiaryEntry(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final content = body['content'] as String?;
    final moodValue = body['mood_value'] as int?;
    final entryDate = body['entry_date'] as String?;

    if (content == null || content.isEmpty) {
      return Response(statusCode: 400, body: 'content is required');
    }

    final recordId = const Uuid().v4();
    final dateStr = entryDate != null ? entryDate.split('T').first : null;
    final dateSql = dateStr != null ? "'$dateStr'" : 'CURRENT_DATE';
    final contentSql = "'${content.replaceAll("'", "''")}'";
    final moodSql = moodValue != null ? moodValue.toString() : 'NULL';

    await _db!.query(
      "INSERT INTO diary_entries (id, user_id, content, mood_value, entry_date) "
      "VALUES ('$recordId', '$userId', $contentSql, $moodSql, $dateSql)",
    );

    final returnedDate = dateStr ?? DateTime.now().toIso8601String().split('T').first;
    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'user_id': userId,
      'content': content,
      'mood_value': moodValue,
      'entry_date': returnedDate,
    });
  } catch (e, stackTrace) {
    print('diary create error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateDiaryEntry(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final content = body['content'] as String?;
    final moodValue = body['mood_value'] as int?;

    if (content == null) {
      return Response(statusCode: 400, body: 'content is required');
    }

    final contentSql = "'${content.replaceAll("'", "''")}'";
    final moodSql = moodValue != null ? moodValue.toString() : 'NULL';

    await _db!.query(
      "UPDATE diary_entries SET content = $contentSql, mood_value = $moodSql "
      "WHERE id = '$id' AND user_id = '$userId'",
    );

    return Response.json(body: {'id': id, 'content': content, 'mood_value': moodValue});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteDiaryEntry(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    await _db!.query("DELETE FROM diary_entries WHERE id = '$id' AND user_id = '$userId'");
    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

void main() async {
  final server = await serve(_handleRequest, InternetAddress.anyIPv4, 8081);
  print('Server running on http://${server.address.host}:${server.port}');
}

// ==================== PSYCHOLOGICAL TESTS ENDPOINTS ====================

/// Метаданные всех доступных тестов (без вопросов)
Future<Response> _getAvailableTests(RequestContext context) async {
  try {
    final tests = [
      {
        'id': 'big_five_ipip_50',
        'title': 'Большая пятёрка (IPIP-50)',
        'description': '5 основных черт личности',
        'icon': '🧠',
        'category': 'personality',
        'questionsCount': 50,
        'durationMinutes': 10,
      },
      {
        'id': 'big_five_ipip_120',
        'title': 'Большая пятёрка (IPIP-120)',
        'description': 'Расширенный тест личности с аспектами',
        'icon': '🧠',
        'category': 'personality',
        'questionsCount': 120,
        'durationMinutes': 20,
      },
      {
        'id': 'phq9',
        'title': 'PHQ-9: Скрининг депрессии',
        'description': 'Оценка депрессивных симптомов',
        'icon': '📉',
        'category': 'clinical',
        'questionsCount': 9,
        'durationMinutes': 3,
      },
      {
        'id': 'gad7',
        'title': 'GAD-7: Скрининг тревожности',
        'description': 'Оценка симптомов тревоги',
        'icon': '😰',
        'category': 'clinical',
        'questionsCount': 7,
        'durationMinutes': 2,
      },
      {
        'id': 'dass21',
        'title': 'DASS-21: Депрессия, тревога, стресс',
        'description': 'Комплексная оценка эмоционального состояния',
        'icon': '📊',
        'category': 'clinical',
        'questionsCount': 21,
        'durationMinutes': 5,
      },
      {
        'id': 'rosenberg_self_esteem',
        'title': 'Шкала самооценки Розенберга',
        'description': 'Оценка уровня самооценки',
        'icon': '💪',
        'category': 'clinical',
        'questionsCount': 10,
        'durationMinutes': 3,
      },
      {
        'id': 'dark_triad_sd3',
        'title': 'Тёмная триада (SD3)',
        'description': 'Нарциссизм, макиавеллизм, психопатия',
        'icon': '🌑',
        'category': 'personality',
        'questionsCount': 27,
        'durationMinutes': 7,
      },
      {
        'id': 'disc',
        'title': 'DISC: Стиль поведения',
        'description': 'Доминирование, влияние, стабильность, добросовестность',
        'icon': '🎯',
        'category': 'behavioral',
        'questionsCount': 28,
        'durationMinutes': 10,
      },
    ];

    return Response.json(body: tests);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить полный тест с вопросами
Future<Response> _getTest(RequestContext context, String testId) async {
  // В production здесь загрузка из БД или файла
  // Пока возвращаем заглушку - клиент сам содержит все тесты
  return Response.json(body: {
    'id': testId,
    'message': 'Test questions are embedded in the client app',
  });
}

/// Отправить ответы теста и получить результат
Future<Response> _submitTest(
    RequestContext context, _AuthContext auth, String testId) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Читаем тело как строку с явным декодированием UTF-8
    final bodyStr = await context.request.body();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    
    final answers = body['answers'] as Map<String, dynamic>?;
    final completedAt = body['completedAt'] as String?;
    final interpretations = body['interpretations'] as Map<String, dynamic>?;

    if (answers == null || answers.isEmpty) {
      return Response(statusCode: 400, body: 'answers are required');
    }

    // Подсчёт баллов по шкалам
    final scores = <String, int>{};
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final answerValue = entry.value;
      
      // Безопасное приведение к int
      if (answerValue is int) {
        scores['question_${questionId}'] = answerValue;
      } else if (answerValue is num) {
        scores['question_${questionId}'] = answerValue.toInt();
      } else {
        print('Invalid answer value for $questionId: $answerValue');
      }
    }

    final recordId = const Uuid().v4();
    final scoresJson = jsonEncode(scores);
    final interpretationsJson = interpretations != null && interpretations.isNotEmpty
        ? jsonEncode(interpretations)
        : null;
    
    // Безопасный парсинг даты
    DateTime completedAtDate;
    try {
      completedAtDate = completedAt != null && completedAt.isNotEmpty
          ? DateTime.parse(completedAt)
          : DateTime.now();
    } catch (e) {
      print('Invalid date format: $completedAt, using current time');
      completedAtDate = DateTime.now();
    }

    print('Inserting test result: testId=$testId, userId=$userId, scores=$scoresJson');

    await _db!.query(
      "INSERT INTO psychological_test_results (id, user_id, test_id, scores, interpretations, completed_at) "
      r"VALUES (@id, @userId, @testId, @scores, @interpretations, @completedAt)",
      substitutionValues: {
        'id': recordId,
        'userId': userId,
        'testId': testId,
        'scores': scoresJson,
        'interpretations': interpretationsJson,
        'completedAt': completedAtDate.toUtc(),
      },
    );

    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'testId': testId,
      'scores': scores,
      'completedAt': completedAtDate.toIso8601String(),
    });
  } catch (e, stackTrace) {
    print('Test submit error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить историю результатов тестов
Future<Response> _getTestResults(
    RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _db!.query(
      "SELECT id, test_id, scores::text, interpretations::text, completed_at "
      "FROM psychological_test_results "
      "WHERE user_id = '$userId' "
      "ORDER BY completed_at DESC",
    );

    final records = results.map((row) => {
          'id': row[0] is String
              ? row[0]
              : Uuid.unparse(row[0] as Uint8List),
          'testId': row[1],
          'scores': row[2],
          'interpretations': row[3],
          'completedAt': row[4],
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить результаты конкретного теста
Future<Response> _getTestResult(
    RequestContext context, _AuthContext auth, String testId) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _db!.query(
      "SELECT id, test_id, scores::text, interpretations::text, completed_at "
      "FROM psychological_test_results "
      "WHERE user_id = '$userId' AND test_id = '$testId' "
      "ORDER BY completed_at DESC",
    );

    final records = results.map((row) => {
          'id': row[0] is String
              ? row[0]
              : Uuid.unparse(row[0] as Uint8List),
          'testId': row[1],
          'scores': row[2],
          'interpretations': row[3],
          'completedAt': row[4],
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== TRUSTED CONTACTS CRUD ====================

/// Получить все доверенные контакты пользователя
Future<Response> _getTrustedContacts(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _db!.query(
      "SELECT id, name, phone, created_at FROM trusted_contacts WHERE user_id = '$userId' ORDER BY created_at DESC",
    );

    final records = results.map((row) => {
          'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
          'name': row[1],
          'phone': row[2],
          'created_at': row[3]?.toString(),
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== Photos / Memory endpoints ====================

/// GET /photos — получить все фото пользователя
Future<Response> _getPhotos(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _db!.query(
      "SELECT id, user_id, image_url, caption, photo_date::text, is_favorite, created_at::text "
      "FROM memory_photos "
      "WHERE user_id = '$userId' "
      "ORDER BY created_at DESC",
    );

    final photos = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'image_url': row[2],
      'caption': row[3],
      'photo_date': row[4],
      'is_favorite': row[5] == true,
      'created_at': row[6],
    }).toList();

    return Response.json(body: photos);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Создать доверенный контакт
Future<Response> _createTrustedContact(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final name = body['name'] as String? ?? '';
  final phone = body['phone'] as String?;

  if (phone == null || phone.isEmpty) {
    return Response(statusCode: 400, body: 'phone is required');
  }

  try {
    final contactId = const Uuid().v4();
    final nameSql = name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';

    await _db!.query(
      "INSERT INTO trusted_contacts (id, user_id, name, phone) VALUES ('$contactId', '$userId', $nameSql, '${phone.replaceAll("'", "''")}')",
    );

    return Response.json(
      statusCode: 201,
      body: {'id': contactId, 'name': name, 'phone': phone},
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
/// POST /photos — загрузить фото (multipart) -> Cloudinary -> БД
Future<Response> _createPhoto(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final contentType = context.request.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      // Альтернатива: JSON с URL
      final body = await context.request.json();
      final imageUrl = body['image_url'] as String?;
      final caption = body['caption'] as String?;
      final photoDate = body['photo_date'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        return Response(statusCode: 400, body: 'image_url is required');
      }

      final photoId = const Uuid().v4();
      final photoDateSql = photoDate != null ? "'$photoDate'" : 'NOW()';
      final captionSql = caption != null ? "'${caption.replaceAll("'", "''")}'" : 'NULL';

      await _db!.query(
        "INSERT INTO memory_photos (id, user_id, image_url, caption, photo_date) "
        "VALUES ('$photoId', '$userId', '$imageUrl', $captionSql, $photoDateSql)",
      );

      return Response.json(statusCode: 201, body: {
        'id': photoId,
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'photo_date': photoDate,
        'is_favorite': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Multipart upload
    final formData = await context.request.formData();
    final file = formData.files['file'];
    final captionField = formData.fields['caption'];
    final photoDateField = formData.fields['photo_date'];

    if (file == null) {
      return Response(statusCode: 400, body: 'file is required');
    }

    final fileBytes = Uint8List.fromList(await file.readAsBytes());
    final fileName = file.name;

    // Определяем MIME-тип
    final mimeType = lookupMimeType(fileName) ?? file.contentType.mimeType;

    // Загружаем в Cloudinary
    final cloudinaryUrl = await _uploadToCloudinary(fileBytes, fileName, mimeType);

    // Сохраняем в БД
    final photoId = const Uuid().v4();
    final photoDate = photoDateField ?? DateTime.now().toIso8601String().split('T').first;
    final caption = captionField;
    final captionSql = caption != null ? "'${caption.replaceAll("'", "''")}'" : 'NULL';

    await _db!.query(
      "INSERT INTO memory_photos (id, user_id, image_url, caption, photo_date) "
      "VALUES ('$photoId', '$userId', '$cloudinaryUrl', $captionSql, '$photoDate')",
    );

    return Response.json(statusCode: 201, body: {
      'id': photoId,
      'user_id': userId,
      'image_url': cloudinaryUrl,
      'caption': caption,
      'photo_date': photoDate,
      'is_favorite': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить доверенный контакт
Future<Response> _updateTrustedContact(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final name = body['name'] as String?;
  final phone = body['phone'] as String?;

  if (phone == null || phone.isEmpty) {
    return Response(statusCode: 400, body: 'phone is required');
  }

  try {
    final nameSql = name != null && name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';
    final phoneSql = phone.replaceAll("'", "''");

    final result = await _db!.query(
      "UPDATE trusted_contacts SET name = $nameSql, phone = '$phoneSql' WHERE id = '$id' AND user_id = '$userId' RETURNING id, name, phone",
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'Contact not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'name': row[1],
      'phone': row[2],
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// PATCH /photos/{id}/favorite — переключить избранное
Future<Response> _togglePhotoFavorite(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _db!.query(
      "SELECT is_favorite FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    final currentFavorite = results.first[0] == true;
    final newFavorite = !currentFavorite;

    await _db!.query(
      "UPDATE memory_photos SET is_favorite = $newFavorite WHERE id = '$id' AND user_id = '$userId'",
    );

    return Response.json(body: {'is_favorite': newFavorite});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Удалить доверенный контакт
Future<Response> _deleteTrustedContact(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final result = await _db!.query(
      "DELETE FROM trusted_contacts WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Contact not found');
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// DELETE /photos/{id} — удалить фото
Future<Response> _deletePhoto(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Получаем URL фото для удаления из Cloudinary
    final photoResults = await _db!.query(
      "SELECT image_url FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (photoResults.isEmpty) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    final imageUrl = photoResults.first[0] as String;

    // Удаляем из БД
    final result = await _db!.query(
      "DELETE FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    // Удаляем из Cloudinary
    try {
      await _deleteFromCloudinary(imageUrl);
    } catch (_) {
      // Игнорируем ошибки удаления из Cloudinary
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Загрузка изображения в Cloudinary через Unsigned upload preset
Future<String> _uploadToCloudinary(Uint8List fileBytes, String fileName, String mimeType) async {
  final publicId = 'citrus_${DateTime.now().millisecondsSinceEpoch}';

  final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl));
  request.files.add(
    await http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: http.MediaType.parse(mimeType),
    ),
  );
  request.fields['upload_preset'] = 'citrus_unsigned';
  request.fields['public_id'] = publicId;

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  print('Cloudinary upload response: ${response.statusCode} $responseBody');

  if (response.statusCode != 200) {
    throw Exception('Cloudinary upload failed: ${response.statusCode} $responseBody');
  }

  final jsonData = json.decode(responseBody);
  return jsonData['secure_url'] as String;
}

/// Удаление изображения из Cloudinary
Future<void> _deleteFromCloudinary(String imageUrl) async {
  try {
    // URL формат: https://res.cloudinary.com/dgeoniumv/image/upload/v1234/citrus_xxx.jpg
    final uri = Uri.parse(imageUrl);
    final pathParts = uri.pathSegments;

    final uploadIndex = pathParts.indexOf('upload');
    if (uploadIndex == -1 || uploadIndex >= pathParts.length - 1) {
      print('Cloudinary delete: cannot parse URL: $imageUrl');
      return;
    }

    var publicId = pathParts.sublist(uploadIndex + 1).join('/');
    if (publicId.startsWith('v') && publicId.contains('/')) {
      publicId = publicId.substring(publicId.indexOf('/') + 1);
    }
    final dotIndex = publicId.lastIndexOf('.');
    if (dotIndex > 0) {
      publicId = publicId.substring(0, dotIndex);
    }

    print('Cloudinary delete: public_id=$publicId');

    // Signed delete — подпись обязательна
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final paramsToSign = 'public_id=$publicId&timestamp=$timestamp';
    final signature = sha1.convert(utf8.encode('$paramsToSign$_cloudinaryApiSecret')).toString();

    final response = await http.post(
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/destroy'),
      body: {
        'public_id': publicId,
        'api_key': _cloudinaryApiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    if (response.statusCode != 200) {
      print('Cloudinary delete failed: ${response.statusCode} ${response.body}');
    } else {
      print('Cloudinary delete success: ${response.body}');
    }
  } catch (e) {
    print('Error deleting from Cloudinary: $e');
  }
}
