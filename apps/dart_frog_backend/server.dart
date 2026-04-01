import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

PostgreSQLConnection? _db;
const _jwtSecret = 'citrus-app-secret-key-change-in-production';

class _AuthContext {
  String? userId;
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

  return Response.json(body: {'message': 'Citrus API'});
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
      "INSERT INTO users (id, email, password_hash, name) VALUES ('$userId', '$email', '$passwordHash', $nameSql)",
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
      "SELECT id, email, name, password_hash FROM users WHERE email = '$email'",
    );

    if (results.isEmpty) {
      return Response(statusCode: 401, body: 'Invalid credentials');
    }

    final row = results.first;
    final storedHash = row[3] as String;
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

void main() async {
  final server = await serve(_handleRequest, InternetAddress.anyIPv4, 8081);
  print('Server running on http://${server.address.host}:${server.port}');
}
