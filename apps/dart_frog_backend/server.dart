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
import 'package:dotenv/dotenv.dart';
import 'lib/services/gigachat_service.dart';
import 'lib/services/email_service.dart';

final _env = DotEnv(includePlatformEnvironment: true);

PostgreSQLConnection? _db;
const _jwtSecret = 'citrus-app-secret-key-change-in-production';

// GigaChat сервис
GigaChatService? _gigachatService;

// Cloudinary конфигурация
const _cloudinaryCloudName = 'dgeoniumv';
const _cloudinaryApiKey = '826774537124372';
const _cloudinaryApiSecret = 'dyJlkMFKHKKFJcnDCbDOPfj7fc0';
const _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/dgeoniumv/image/upload';

// Wikipedia API конфигурация для статей ментального здоровья (русский)
const _wikipediaTopicsRu = {
  'anxiety': '%D0%A2%D1%80%D0%B5%D0%B2%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D1%8C',
  'depression': '%D0%94%D0%B5%D0%BF%D1%80%D0%B5%D1%81%D1%81%D0%B8%D1%8F',
  'sleep': '%D0%93%D0%B8%D0%B3%D0%B8%D0%B5%D0%BD%D0%B0_%D1%81%D0%BD%D0%B0',
  'stress': '%D0%A1%D1%82%D1%80%D0%B5%D1%81%D1%81',
  'self-esteem': '%D0%A1%D0%B0%D0%BC%D0%BE%D0%BE%D1%86%D0%B5%D0%BD%D0%BA%D0%B0',
  'relationships': '%D0%9C%D0%B5%D0%B6%D0%BB%D0%B8%D1%87%D0%BD%D0%BE%D1%81%D1%82%D0%BD%D1%8B%D0%B5_%D0%BE%D1%82%D0%BD%D0%BE%D1%88%D0%B5%D0%BD%D0%B8%D1%8F',
  'mindfulness': '%D0%9E%D1%81%D0%BE%D0%B7%D0%BD%D0%B0%D0%BD%D0%BD%D0%BE%D1%81%D1%82%D1%8C_(%D0%BF%D1%81%D0%B8%D1%85%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D1%8F)',
  'panic_attacks': '%D0%9F%D0%B0%D0%BD%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F_%D0%B0%D1%82%D0%B0%D0%BA%D0%B0',
  'burnout': '%D0%AD%D0%BC%D0%BE%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D0%B2%D1%8B%D0%B3%D0%BE%D1%80%D0%B0%D0%BD%D0%B8%D0%B5',
  'meditation': '%D0%9C%D0%B5%D0%B4%D0%B8%D1%82%D0%B0%D1%86%D0%B8%D1%8F',
  'cognitive_behavioral_therapy': '%D0%9A%D0%BE%D0%B3%D0%BD%D0%B8%D1%82%D0%B8%D0%B2%D0%BD%D0%BE-%D0%BF%D0%BE%D0%B2%D0%B5%D0%B4%D0%B5%D0%BD%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F_%D0%BF%D1%81%D0%B8%D1%85%D0%BE%D1%82%D0%B5%D1%80%D0%B0%D0%BF%D0%B8%D1%8F',
  'loneliness': '%D0%9E%D0%B4%D0%B8%D0%BD%D0%BE%D1%87%D0%B5%D1%81%D1%82%D0%B2%D0%BE',
  'anger': '%D0%93%D0%BD%D0%B5%D0%B2',
  'self_care': '%D0%A1%D0%B0%D0%BC%D0%BE%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C',
  'emotional_intelligence': '%D0%AD%D0%BC%D0%BE%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9_%D0%B8%D0%BD%D1%82%D0%B5%D0%BB%D0%BB%D0%B5%D0%BA%D1%82',
};

const _wikipediaTitlesRu = {
  'anxiety': 'Тревожность',
  'depression': 'Депрессия',
  'sleep': 'Гигиена сна',
  'stress': 'Стресс',
  'self-esteem': 'Самооценка',
  'relationships': 'Межличностные отношения',
  'mindfulness': 'Осознанность',
  'panic_attacks': 'Паническая атака',
  'burnout': 'Эмоциональное выгорание',
  'meditation': 'Медитация',
  'cognitive_behavioral_therapy': 'Когнитивно-поведенческая терапия',
  'loneliness': 'Одиночество',
  'anger': 'Гнев',
  'self_care': 'Самопомощь',
  'emotional_intelligence': 'Эмоциональный интеллект',
};

const _wikipediaCategoryMap = {
  'anxiety': 'anxiety',
  'depression': 'depression',
  'sleep': 'sleep',
  'stress': 'stress',
  'self-esteem': 'self-esteem',
  'relationships': 'relationships',
  'mindfulness': 'mindfulness',
  'panic_attacks': 'anxiety',
  'burnout': 'stress',
  'meditation': 'mindfulness',
  'cognitive_behavioral_therapy': 'stress',
  'loneliness': 'depression',
  'anger': 'stress',
  'self_care': 'mindfulness',
  'emotional_intelligence': 'relationships',
};

// Кэш Wikipedia статей
Map<String, Map<String, dynamic>> _wikipediaCache = {};
DateTime? _wikipediaCacheTime;
const _cacheDurationMinutes = 60;

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

  // Инициализация GigaChat сервиса (если ещё не инициализирован)
  if (_gigachatService == null) {
    try {
      _gigachatService = GigaChatService();
      print('GigaChat service initialized!');
    } catch (e) {
      print('Failed to initialize GigaChat service: $e');
    }
  }

  // Инициализация Email сервиса (Yandex SMTP) — учётные данные захардкожены в EmailService
  if (!EmailService.isConfigured) {
    EmailService.init();
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
  if (path == '/auth/forgot-password' && method == HttpMethod.post) {
    return _forgotPassword(context);
  }
  if (path == '/auth/reset-password' && method == HttpMethod.post) {
    return _resetPassword(context);
  }

  // GET /themes - получить список тем
  if (path == '/themes' && method == HttpMethod.get) {
    return _getThemes(context);
  }

  // GET /user/theme - получить тему пользователя
  if (path == '/user/theme' && method == HttpMethod.get) {
    return _getUserTheme(context);
  }

  // PUT /user/theme - обновить тему пользователя
  if (path == '/user/theme' && method == HttpMethod.put) {
    return _updateUserTheme(context);
  }

  // GET /user/profile - получить профиль пользователя
  if (path == '/user/profile' && method == HttpMethod.get) {
    return _getUserProfile(context);
  }

  // PUT /user/profile - обновить профиль пользователя
  if (path == '/user/profile' && method == HttpMethod.put) {
    return _updateUserProfile(context);
  }

  // POST /user/avatar - загрузить аватар
  if (path == '/user/avatar' && method == HttpMethod.post) {
    return _uploadUserAvatar(context);
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

  // GET /analytics/stats - статистика активности (требует авторизации)
  if (path == '/analytics/stats' && method == HttpMethod.get) {
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
    return _getAnalyticsStats(context, authContext);
  }

  // POST /exercises/complete - отметить упражнение как выполненное (требует авторизации)
  if (path == '/exercises/complete' && method == HttpMethod.post) {
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
    return _completeExercise(context, authContext);
  }

  // GET /exercises/stats - статистика упражнений (требует авторизации)
  if (path == '/exercises/stats' && method == HttpMethod.get) {
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
    return _getExerciseStats(context, authContext);
  }

  // GET /exercises - история упражнений (требует авторизации)
  if (path == '/exercises' && method == HttpMethod.get) {
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
    return _getExercises(context, authContext);
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

  // Articles endpoints (требуют авторизации)
  if (path.startsWith('/articles')) {
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

  // GET /articles
  if (path == '/articles' && method == HttpMethod.get) {
    return _getArticles(context, authContext);
  }

  // POST /articles
  if (path == '/articles' && method == HttpMethod.post) {
    return _createArticle(context, authContext);
  }

  // PUT /articles/{id}
  if (path.startsWith('/articles/') && method == HttpMethod.put) {
    final id = path.substring('/articles/'.length);
    return _updateArticle(context, authContext, id);
  }

  // DELETE /articles/{id}
  if (path.startsWith('/articles/') && method == HttpMethod.delete) {
    final id = path.substring('/articles/'.length);
    return _deleteArticle(context, authContext, id);
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

  // POST /chat - чат с GigaChat AI (требует авторизации)
  if (path == '/chat' && method == HttpMethod.post) {
    return _chatWithAI(context);
  }

  // GET /chat/messages - получить историю сообщений пользователя
  if (path == '/chat/messages' && method == HttpMethod.get) {
    return _getChatMessages(context);
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
        'avatar_url': null,
        'phone': null,
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
      "SELECT id, email, name, theme_id, password_hash, avatar_url, phone FROM users WHERE email = '$email'",
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
      'avatar_url': row[5] as String?,
      'phone': row[6] as String?,
      'token': token,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Запросить сброс пароля — отправить код на email
Future<Response> _forgotPassword(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;

    if (email == null || email.isEmpty) {
      return Response(statusCode: 400, body: 'email is required');
    }

    // Проверяем, существует ли пользователь
    final results = await _db!.query(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (results.isEmpty) {
      // В целях безопасности всегда возвращаем 200, чтобы не раскрывать существование email
      return Response.json(body: {'message': 'Если аккаунт с таким email существует, код отправлен'});
    }

    final userId = results.first[0] as String;

    // Инвалидируем старые коды
    await _db!.query(
      "UPDATE password_reset_tokens SET used = true WHERE user_id = '$userId' AND used = false",
    );

    // Генерируем 6-значный код
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

    // Сохраняем код (действителен 15 минут)
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    final tokenId = const Uuid().v4();

    await _db!.query(
      "INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES ('$tokenId', '$userId', '$code', '${expiresAt.toIso8601String()}')",
    );

    // Отправляем email
    final sent = await EmailService.sendPasswordResetCode(email, code);
    if (!sent) {
      print('Failed to send reset email to $email, but code is stored');
    }

    return Response.json(body: {'message': 'Если аккаунт с таким email существует, код отправлен'});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Сбросить пароль по коду
Future<Response> _resetPassword(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final code = body['code'] as String?;
    final newPassword = body['new_password'] as String?;

    if (email == null || code == null || newPassword == null) {
      return Response(statusCode: 400, body: 'email, code and new_password are required');
    }

    if (newPassword.length < 6) {
      return Response(statusCode: 400, body: 'Password must be at least 6 characters');
    }

    // Находим пользователя
    final userResults = await _db!.query(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (userResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final userId = userResults.first[0] as String;

    // Проверяем код
    final tokenResults = await _db!.query(
      "SELECT id, expires_at FROM password_reset_tokens WHERE user_id = '$userId' AND code = '$code' AND used = false ORDER BY created_at DESC LIMIT 1",
    );

    if (tokenResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final expiresAt = tokenResults.first[1] as DateTime;
    if (DateTime.now().isAfter(expiresAt)) {
      // Код просрочен
      await _db!.query(
        "UPDATE password_reset_tokens SET used = true WHERE id = '${tokenResults.first[0]}'",
      );
      return Response(statusCode: 400, body: 'Code has expired');
    }

    // Помечаем код как использованный
    await _db!.query(
      "UPDATE password_reset_tokens SET used = true WHERE id = '${tokenResults.first[0]}'",
    );

    // Обновляем пароль
    final passwordHash = _hashPassword(newPassword);
    await _db!.query(
      "UPDATE users SET password_hash = '$passwordHash' WHERE id = '$userId'",
    );

    return Response.json(body: {'message': 'Password has been reset successfully'});
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

/// Получить тему пользователя
Future<Response> _getUserTheme(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _db!.query(
      "SELECT theme_id FROM users WHERE id = '$userId'",
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final themeId = result.first[0] as String?;
    return Response.json(body: {'theme_id': themeId});
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

/// Получить профиль пользователя
Future<Response> _getUserProfile(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _db!.query(
      "SELECT id, email, name, theme_id, avatar_url, phone FROM users WHERE id = '$userId'",
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] as String,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'avatar_url': row[4] as String?,
      'phone': row[5] as String?,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить профиль пользователя (имя, телефон)
Future<Response> _updateUserProfile(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;
    final body = await context.request.json();

    final name = body['name'] as String?;
    final phone = body['phone'] as String?;

    final nameSql = name != null && name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';
    final phoneSql = phone != null && phone.isNotEmpty ? "'${phone.replaceAll("'", "''")}'" : 'NULL';

    await _db!.query(
      "UPDATE users SET name = $nameSql, phone = $phoneSql WHERE id = '$userId'",
    );

    // Возвращаем обновлённый профиль
    final result = await _db!.query(
      "SELECT id, email, name, theme_id, avatar_url, phone FROM users WHERE id = '$userId'",
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] as String,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'avatar_url': row[4] as String?,
      'phone': row[5] as String?,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Загрузить аватар пользователя
Future<Response> _uploadUserAvatar(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    // Multipart upload
    final formData = await context.request.formData();
    final file = formData.files['file'];

    if (file == null) {
      return Response(statusCode: 400, body: 'file is required');
    }

    final fileBytes = Uint8List.fromList(await file.readAsBytes());
    final fileName = file.name;
    final mimeType = lookupMimeType(fileName) ?? file.contentType.mimeType;

    // Загружаем в Cloudinary
    final cloudinaryUrl = await _uploadToCloudinary(fileBytes, fileName, mimeType);

    // Обновляем аватар в БД
    await _db!.query(
      "UPDATE users SET avatar_url = '$cloudinaryUrl' WHERE id = '$userId'",
    );

    return Response.json(body: {
      'avatar_url': cloudinaryUrl,
    });
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
      final escapedSearch = search.replaceAll("'", "''");
      whereClause += " AND content ILIKE '%$escapedSearch%'";
    }

    final results = await _db!.query(
      "SELECT id, user_id, content, mood_value, entry_date::text, created_at::text "
      "FROM diary_entries $whereClause ORDER BY entry_date DESC, created_at DESC",
    );
    print('DB entry_date values: ${results.map((r) => r[4]).toList()}');

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
    print('Backend received entryDate: $entryDate');
    final dateStr = entryDate != null ? entryDate : DateTime.now().toIso8601String();
    print('Backend using dateStr: $dateStr');
    final dateSql = "'$dateStr'";
    final contentSql = "'${content.replaceAll("'", "''")}'";
    final moodSql = moodValue != null ? moodValue.toString() : 'NULL';

    await _db!.query(
      "INSERT INTO diary_entries (id, user_id, content, mood_value, entry_date) "
      "VALUES ('$recordId', '$userId', $contentSql, $moodSql, $dateSql)",
    );

    final returnedDate = dateStr;
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

/// POST /chat - чат с GigaChat AI
Future<Response> _chatWithAI(RequestContext context) async {
  // Проверяем, инициализирован ли GigaChat сервис
  if (_gigachatService == null) {
    return Response.json(
      statusCode: 503,
      body: {
        'error': 'GigaChat service is not configured',
        'message': 'Установите переменные окружения GIGACHAT_AUTHORIZATION_KEY',
      },
    );
  }

  try {
    final body = await context.request.json();
    final message = body['message'] as String?;
    final systemPrompt = body['system_prompt'] as String?;
    final temperature = (body['temperature'] as num?)?.toDouble() ?? 0.7;
    final maxTokens = body['max_tokens'] as int? ?? 2048; // Увеличено для аналитики

    if (message == null || message.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'message is required'},
      );
    }

    // Получаем userId из токена (если есть авторизация)
    String? userId;
    final token = _extractToken(context);
    if (token != null) {
      try {
        final jwt = JWT.verify(token, SecretKey(_jwtSecret));
        userId = jwt.payload['user_id'] as String?;
      } catch (_) {}
    }

    // Определяем system prompt
    String finalSystemPrompt = systemPrompt ?? 'Ты полезный ассистент по имени Цитрус. Ты помогаешь пользователям следить за своим ментальным здоровьем, даёшь советы по улучшению настроения, борьбе с тревогой и поддержанию хорошего эмоционального состояния. Отвечай дружелюбно и поддерживающе. Используй Markdown: **жирный** для ключевых моментов, *курсив* для акцентов.';
    
    // Если сообщение содержит аналитику, адаптируем prompt
    if (message.contains('📊') && message.contains('Аналитика')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе свою аналитику настроения и активности. 
Проанализируй данные, дай полезные инсайты и поддерживающий комментарий. 
Обращай внимание на тренды, серийность дней и распределение настроения.
Будь конкретным и давай практические рекомендации.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.''';
    } else if (message.contains('📓') && message.contains('Записи дневника')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе свои записи из дневника.

ВАЖНО: Проанализируй именно СОДЕРЖАНИЕ каждой записи. Обращай внимание на:
1. Конкретные события и действия, которые описывает пользователь
2. Эмоции и чувства, которые он выражает
3. Повторяющиеся темы, слова или ситуации в разных записях
4. Есть ли связь между настроением и содержанием записей
5. Позитивные моменты и достижения
6. Возможные источники стресса или тревоги

ДАЙ КОНКРЕТНЫЙ анализ: упоминай события, детали и фразы из записей пользователя.
НЕ пиши общие фразы типа "записи краткие" или "нет детализации" — работай с тем что есть.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.
Будь тёплым, поддерживающим и конкретным.''';
    } else if (message.contains('😴') && message.contains('Анализ сна')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе данные о своём сне.
Проанализируй качество сна, дай рекомендации по улучшению гигиены сна и объясни как сон влияет на ментальное здоровье.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.''';
    }

    // Отправляем сообщение в GigaChat
    final startTime = DateTime.now();
    final response = await _gigachatService!.chat(
      message,
      systemPrompt: finalSystemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;

    // Сохраняем сообщения в БД (если пользователь авторизован)
    if (userId != null && _db != null) {
      try {
        final msgId = const Uuid().v4();
        final escapedUser = message.replaceAll("'", "''");
        final escapedResponse = response.replaceAll("'", "''");
        await _db!.query(
          """
          INSERT INTO chat_messages 
          (id, user_id, user_message, ai_response, created_at, response_time_ms, model_used)
          VALUES 
          ('$msgId', '$userId', '$escapedUser', '$escapedResponse', NOW(), $responseTime, 'GigaChat')
          """,
        );
      } catch (e) {
        print('Warning: failed to save chat message: $e');
      }
    }

    return Response.json(
      statusCode: 200,
      body: {
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    print('Error in /chat endpoint: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to get AI response: $e'},
    );
  }
}

/// GET /chat/messages - получить историю сообщений пользователя
Future<Response> _getChatMessages(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _db!.query(
      '''SELECT id, user_message, ai_response, created_at 
         FROM chat_messages 
         WHERE user_id = '$userId' 
         ORDER BY created_at DESC 
         LIMIT 100''',
    );

    final messages = result.map((row) => {
      'id': row[0] as String,
      'user_message': row[1] as String,
      'ai_response': row[2] as String,
      'created_at': (row[3] as DateTime).toIso8601String(),
    }).toList();

    return Response.json(body: messages);
  } catch (e) {
    // Если таблица ещё не создана, возвращаем пустой список
    return Response.json(body: <Map<String, dynamic>>[]);
  }
}

/// GET /analytics/stats - полная статистика активности пользователя
Future<Response> _getAnalyticsStats(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;

  try {
    // Количество сообщений в чате
    int chatMessages = 0;
    try {
      final chatResult = await _db!.query(
        "SELECT COUNT(*) FROM chat_messages WHERE user_id = '$userId'",
      );
      chatMessages = int.parse(chatResult.first[0].toString());
    } catch (_) {}

    // Количество пройденных тестов
    int testsCompleted = 0;
    try {
      final testResult = await _db!.query(
        "SELECT COUNT(*) FROM psychological_test_results WHERE user_id = '$userId'",
      );
      testsCompleted = int.parse(testResult.first[0].toString());
    } catch (_) {}

    // Количество выполненных упражнений
    int exercisesCompleted = 0;
    try {
      final exerciseResult = await _db!.query(
        "SELECT COALESCE(SUM(completion_count), 0) FROM user_exercises WHERE user_id = '$userId'",
      );
      exercisesCompleted = int.parse(exerciseResult.first[0].toString());
    } catch (_) {}

    return Response.json(body: {
      'chatMessages': chatMessages,
      'testsCompleted': testsCompleted,
      'exercisesCompleted': exercisesCompleted,
    });
  } catch (e) {
    print('Error in /analytics/stats: $e');
    return Response.json(
      statusCode: 200,
      body: {
        'chatMessages': 0,
        'testsCompleted': 0,
        'exercisesCompleted': 0,
      },
    );
  }
}

/// POST /exercises/complete - отметить упражнение как выполненное
Future<Response> _completeExercise(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.body();
    final data = json.decode(body);

    final exerciseId = data['exercise_id'] as String?;
    final exerciseType = data['exercise_type'] as String?;
    final title = data['title'] as String?;
    final durationMinutes = data['duration_minutes'] as int?;
    final difficultyLevel = data['difficulty_level'] as int?;
    final userNotes = data['user_notes'] as String?;
    final moodBefore = data['mood_before'] as int?;
    final moodAfter = data['mood_after'] as int?;

    if (exerciseId == null || exerciseType == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'exercise_id and exercise_type are required'},
      );
    }

    final id = const Uuid().v4();
    await _db!.query(
      """
      INSERT INTO user_exercises 
      (id, user_id, exercise_id, exercise_type, title, duration_minutes, difficulty_level, user_notes, mood_before, mood_after, completed_at)
      VALUES 
      ('$id', '$userId', '$exerciseId', '$exerciseType', ${title != null ? "'${title.replaceAll("'", "''")}'" : 'NULL'}, ${durationMinutes != null ? durationMinutes : 'NULL'}, ${difficultyLevel != null ? difficultyLevel : 'NULL'}, ${userNotes != null ? "'${userNotes.replaceAll("'", "''")}'" : 'NULL'}, ${moodBefore != null ? moodBefore : 'NULL'}, ${moodAfter != null ? moodAfter : 'NULL'}, NOW())
      """,
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': id,
        'message': 'Exercise completed successfully',
      },
    );
  } catch (e) {
    print('Error completing exercise: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
  }
}

/// GET /exercises/stats - расширенная статистика упражнений
Future<Response> _getExerciseStats(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Общая статистика
    int totalExercises = 0;
    int totalMinutes = 0;
    Map<String, int> byType = {};
    int last7Days = 0;
    int last30Days = 0;

    // Общее количество упражнений
    final totalResult = await _db!.query(
      "SELECT COUNT(*) FROM user_exercises WHERE user_id = '$userId'",
    );
    totalExercises = int.parse(totalResult.first[0].toString());

    // Общее время
    final minutesResult = await _db!.query(
      "SELECT COALESCE(SUM(duration_minutes), 0) FROM user_exercises WHERE user_id = '$userId'",
    );
    totalMinutes = int.parse(minutesResult.first[0].toString());

    // Группировка по типам
    final typeResult = await _db!.query(
      "SELECT exercise_type, COUNT(*) FROM user_exercises WHERE user_id = '$userId' GROUP BY exercise_type",
    );
    for (final row in typeResult) {
      byType[row[0].toString()] = int.parse(row[1].toString());
    }

    // За последние 7 дней
    final last7Result = await _db!.query(
      "SELECT COUNT(*) FROM user_exercises WHERE user_id = '$userId' AND completed_at > NOW() - INTERVAL '7 days'",
    );
    last7Days = int.parse(last7Result.first[0].toString());

    // За последние 30 дней
    final last30Result = await _db!.query(
      "SELECT COUNT(*) FROM user_exercises WHERE user_id = '$userId' AND completed_at > NOW() - INTERVAL '30 days'",
    );
    last30Days = int.parse(last30Result.first[0].toString());

    // Средняя продолжительность
    double avgDuration = 0;
    final avgResult = await _db!.query(
      "SELECT AVG(duration_minutes) FROM user_exercises WHERE user_id = '$userId' AND duration_minutes IS NOT NULL",
    );
    if (avgResult.first[0] != null) {
      avgDuration = double.parse(avgResult.first[0].toString());
    }

    return Response.json(body: {
      'totalExercises': totalExercises,
      'totalMinutes': totalMinutes,
      'byType': byType,
      'last7Days': last7Days,
      'last30Days': last30Days,
      'averageDurationMinutes': avgDuration.roundToDouble(),
    });
  } catch (e) {
    print('Error in /exercises/stats: $e');
    return Response.json(
      statusCode: 200,
      body: {
        'totalExercises': 0,
        'totalMinutes': 0,
        'byType': {},
        'last7Days': 0,
        'last30Days': 0,
        'averageDurationMinutes': 0,
      },
    );
  }
}

/// GET /exercises - история выполненных упражнений
Future<Response> _getExercises(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final queryParameters = context.request.uri.queryParameters;
    final limit = int.tryParse(queryParameters['limit'] ?? '50') ?? 50;
    final offset = int.tryParse(queryParameters['offset'] ?? '0') ?? 0;
    final exerciseType = queryParameters['type'];

    String whereClause = "WHERE user_id = '$userId'";
    if (exerciseType != null) {
      whereClause += " AND exercise_type = '$exerciseType'";
    }

    final results = await _db!.query(
      """
      SELECT id, exercise_id, exercise_type, title, completed_at, duration_minutes, difficulty_level, user_notes, mood_before, mood_after
      FROM user_exercises 
      $whereClause
      ORDER BY completed_at DESC
      LIMIT $limit OFFSET $offset
      """,
    );

    final exercises = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'exercise_id': row[1],
        'exercise_type': row[2],
        'title': row[3],
        'completed_at': row[4].toString(),
        'duration_minutes': row[5],
        'difficulty_level': row[6],
        'user_notes': row[7],
        'mood_before': row[8],
        'mood_after': row[9],
      };
    }).toList();

    // Получаем общее количество для пагинации
    final countResult = await _db!.query(
      "SELECT COUNT(*) FROM user_exercises $whereClause",
    );
    final total = int.parse(countResult.first[0].toString());

    return Response.json(body: {
      'exercises': exercises,
      'total': total,
      'limit': limit,
      'offset': offset,
    });
  } catch (e) {
    print('Error in /exercises: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
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

/// GET /articles — получить все статьи пользователя + системные + Wikipedia
Future<Response> _getArticles(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Загружаем статьи из БД
    final results = await _db!.query(
      "SELECT id, user_id, title, content, category, is_custom, source, tags, created_at FROM articles WHERE user_id = '$userId' OR user_id IS NULL ORDER BY created_at DESC",
    );

    final articles = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
        'title': row[2],
        'content': row[3],
        'category': row[4],
        'is_custom': row[5],
        'source': row[6],
        'tags': row[7],
        'created_at': row[8].toString(),
      };
    }).toList();

    // Добавляем Wikipedia статьи
    final wikiArticles = await _getWikipediaArticles();
    articles.addAll(wikiArticles);

    return Response.json(body: articles);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Загрузить статьи из Wikipedia API (русский)
Future<List<Map<String, dynamic>>> _getWikipediaArticles() async {
  // Проверяем кэш
  final now = DateTime.now();
  if (_wikipediaCache.isNotEmpty &&
      _wikipediaCacheTime != null &&
      now.difference(_wikipediaCacheTime!).inMinutes < _cacheDurationMinutes) {
    return _wikipediaCache.values.toList();
  }

  _wikipediaCache.clear();

  for (final entry in _wikipediaTopicsRu.entries) {
    final wikiKey = entry.key;
    final wikiTitle = entry.value;
    final category = _wikipediaCategoryMap[wikiKey] ?? 'mindfulness';
    final displayTitle = _wikipediaTitlesRu[wikiKey] ?? wikiKey;

    try {
      final url = Uri.parse(
        'https://ru.wikipedia.org/api/rest_v1/page/html/$wikiTitle',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'CitrusApp/1.0 (mental health app)',
        'Accept': 'text/html',
      });

      if (response.statusCode == 200) {
        final html = response.body;
        final markdownContent = _htmlToMarkdown(html);

        if (markdownContent.isNotEmpty && markdownContent.length > 100) {
          final wikiArticle = {
            'id': 'wiki_$wikiKey',
            'user_id': null,
            'title': displayTitle,
            'content': markdownContent,
            'category': category,
            'is_custom': false,
            'created_at': now.toIso8601String(),
            'source': 'wikipedia',
            'tags': [category],
          };
          _wikipediaCache[wikiKey] = wikiArticle;
          print('Wikipedia: загружена статья "$displayTitle" (${markdownContent.length} символов)');
        }
      } else {
        print('Wikipedia: ошибка ${response.statusCode} для $wikiKey');
      }
    } catch (e) {
      print('Wikipedia API error for $wikiKey: $e');
    }

    // Задержка чтобы не спамить API
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Добавляем локальные системные статьи
  final localArticles = _getLocalArticles(now);
  for (final article in localArticles) {
    _wikipediaCache[article['id'] as String] = article;
  }

  _wikipediaCacheTime = now;
  print('Wikipedia: всего загружено ${_wikipediaCache.length} статей');
  return _wikipediaCache.values.toList();
}

/// Конвертация HTML Wikipedia в Markdown
String _htmlToMarkdown(String html) {
  String text = html;

  // Извлекаем содержимое mw-body-content — ищем div с этим классом
  final bodyMatch = RegExp(r'<div[^>]*?class="[^"]*?mw-body-content[^"]*?"[^>]*?>(.*?)</div>\s*</div>', dotAll: true).firstMatch(text);
  if (bodyMatch != null) {
    text = bodyMatch.group(1)!;
  } else {
    // Альтернативный паттерн — ищем после contentSub
    final altMatch = RegExp(r'id="contentSub"[^>]*>.*?</div>(.*?)</div>', dotAll: true).firstMatch(text);
    if (altMatch != null) {
      text = altMatch.group(1)!;
    } else {
      // Если ничего не нашли — пробуем просто взять всё после body
      final bodyTagMatch = RegExp(r'<body[^>]*>(.*)', dotAll: true).firstMatch(text);
      if (bodyTagMatch != null) {
        text = bodyTagMatch.group(1)!;
      }
    }
  }

  // Удаляем скрипты и стили
  text = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<link[^>]*/?>'), '');
  text = text.replaceAll(RegExp(r'<meta[^>]*/?>'), '');

  // Удаляем навигационные элементы
  text = text.replaceAll(RegExp(r'<nav[^>]*>.*?</nav>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<div[^>]*class="[^"]*navbox[^"]*"[^>]*>.*?</div>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<div[^>]*class="[^"]*sistersitebox[^"]*"[^>]*>.*?</div>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<div[^>]*class="[^"]*refbegin[^"]*"[^>]*>.*?</div>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<div[^>]*class="[^"]*references[^"]*"[^>]*>.*?</div>', dotAll: true), '');

  // Удаляем таблицы (инфобоксы, навигация)
  text = text.replaceAll(RegExp(r'<table[^>]*class="[^"]*infobox[^"]*"[^>]*>.*?</table>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<table[^>]*class="[^"]*navbox[^"]*"[^>]*>.*?</table>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<table[^>]*class="[^"]*toc[^"]*"[^>]*>.*?</table>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<table[^>]*>.*?</table>', dotAll: true), '');

  // Удаляем ссылки на источники [число]
  text = text.replaceAll(RegExp(r'<sup[^>]*>.*?</sup>', dotAll: true), '');
  text = text.replaceAll(RegExp(r'<a[^>]*class="[^"]*reference[^"]*"[^>]*>.*?</a>', dotAll: true), '');

  // Заголовки h1-h6 → Markdown #
  text = text.replaceAllMapped(RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', dotAll: true), (m) {
    final level = int.parse(m.group(1)!);
    final content = _stripHtml(m.group(2)!);
    if (content.isEmpty) return '';
    // Пропускаем первый h1 (это заголовок страницы)
    if (level == 1) return '';
    return '\n\n${'#' * level} $content\n\n';
  });

  // Жирный
  text = text.replaceAllMapped(RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true), (m) => '**${_stripHtml(m.group(1)!)}**');
  text = text.replaceAllMapped(RegExp(r'<b[^>]*>(.*?)</b>', dotAll: true), (m) => '**${_stripHtml(m.group(1)!)}**');

  // Курсив
  text = text.replaceAllMapped(RegExp(r'<em[^>]*>(.*?)</em>', dotAll: true), (m) => '*${_stripHtml(m.group(1)!)}*');
  text = text.replaceAllMapped(RegExp(r'<i[^>]*>(.*?)</i>', dotAll: true), (m) => '*${_stripHtml(m.group(1)!)}*');

  // Списки
  text = text.replaceAllMapped(RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true), (m) {
    final content = _stripHtml(m.group(1)!).trim();
    return '\n- $content';
  });

  // Параграфы
  text = text.replaceAllMapped(RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true), (m) {
    final content = _stripHtml(m.group(1)!).trim();
    if (content.isEmpty) return '';
    return '\n\n$content\n\n';
  });

  // Line breaks
  text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');

  // Удаляем все оставшиеся теги
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');

  // Декодируем HTML entities
  text = text.replaceAll('&nbsp;', ' ');
  text = text.replaceAll('&amp;', '&');
  text = text.replaceAll('&lt;', '<');
  text = text.replaceAll('&gt;', '>');
  text = text.replaceAll('&quot;', '"');
  text = text.replaceAll('&#39;', "'");
  text = text.replaceAll('&mdash;', '—');
  text = text.replaceAll('&ndash;', '–');
  text = text.replaceAll('&#160;', ' ');
  text = text.replaceAll(RegExp(r'&#\d+;'), ' ');

  // Убираем множественные пустые строки
  text = text.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
  text = text.trim();

  // Если контент слишком короткий — возвращаем пустую строку
  if (text.length < 200) {
    return '';
  }

  // Добавляем источник
  text += '\n\n---\n*Источник: Русская Wikipedia*';

  return text;
}

/// Удалить HTML теги из строки
String _stripHtml(String html) {
  String text = html;
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text.replaceAll('&nbsp;', ' ');
  text = text.replaceAll('&amp;', '&');
  text = text.replaceAll('&lt;', '<');
  text = text.replaceAll('&gt;', '>');
  text = text.replaceAll('&quot;', '"');
  text = text.replaceAll('&#39;', "'");
  text = text.replaceAll('&mdash;', '—');
  text = text.replaceAll('&ndash;', '–');
  text = text.replaceAll('&#160;', ' ');
  return text.trim();
}

/// Локальные системные статьи на русском
List<Map<String, dynamic>> _getLocalArticles(DateTime now) {
  return [
    {
      'id': 'local_breathing',
      'user_id': null,
      'title': 'Дыхательные техники для снятия тревоги',
      'content': '''## Дыхание 4-7-8

Эта техника помогает быстро успокоиться и снижает уровень тревоги.

**Как выполнять:**

1. Вдох через нос на **4 счёта**
2. Задержка дыхания на **7 счётов**
3. Медленный выдох через рот на **8 счётов**
4. Повторите 4 цикла

## Квадратное дыхание

Помогает сосредоточиться и снизить стресс.

**Техника:**

- Вдох на 4 счёта
- Задержка на 4 счёта
- Выдох на 4 счёта
- Задержка на 4 счёта
- Повторите 5-10 раз

## Почему это работает

Глубокое дыхание активирует **парасимпатическую нервную систему**, которая отвечает за расслабление. Это снижает уровень кортизола и адреналина в крови.

> **Совет:** Практикуйте дыхательные техники 2-3 раза в день, даже когда не испытываете тревогу. Это поможет закрепить навык.''',
      'category': 'anxiety',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['anxiety'],
    },
    {
      'id': 'local_sleep_tips',
      'user_id': null,
      'title': '10 советов для здорового сна',
      'content': '''## Как улучшить качество сна

### 1. Ложитесь и вставайте в одно время
Даже в выходные. Это настраивает ваши **циркадные ритмы**.

### 2. Создайте ритуал перед сном
- Тёплый душ или ванна
- Чтение книги (не экран!)
- Медитация или дыхательные упражнения

### 3. Оптимизируйте спальню
- Температура: **18-20°C**
- Полная темнота
- Тишина или белый шум

### 4. Ограничьте экраны перед сном
Голубой свет экранов подавляет **мелатонин**. За 1-2 часа до сна уберите телефон и компьютер.

### 5. Не ешьте тяжёлую пищу за 3 часа до сна
Пищеварение мешает организму расслабиться.

### 6. Ограничьте кофеин
Не пейте кофе, чай или энергетики после **14:00**. Кофеин действует до 8 часов.

### 7. Физическая активность
Регулярные упражнения улучшают качество сна, но не тренируйтесь за 3 часа до сна.

### 8. Не смотрите на часы
Если не можете уснуть — встаньте и займитесь чем-то спокойным 20 минут.

### 9. Ограничьте дневной сон
Если спите днём — не более **20-30 минут** до 15:00.

### 10. Записывайте мысли перед сном
Заведите **дневник тревог**. Запишите все беспокоящие мысли — это освободит голову.

---
*На основе рекомендаций Национального фонда сна (NSF)*''',
      'category': 'sleep',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['sleep'],
    },
    {
      'id': 'local_stress_management',
      'user_id': null,
      'title': 'Управление стрессом: практические техники',
      'content': '''## Что такое стресс

**Стресс** — это естественная реакция организма на вызовы и угрозы. Кратковременный стресс может быть полезным, но хронический стресс разрушительно влияет на здоровье.

## Техника заземления 5-4-3-2-1

Когда вас захлёстывает стресс, используйте этот метод:

- **5** вещей, которые вы **видите**
- **4** вещи, которые вы можете **потрогать**
- **3** вещи, которые вы **слышите**
- **2** вещи, которые вы можете **понюхать**
- **1** вещь, которую вы можете **попробовать на вкус**

## Прогрессивная мышечная релаксация

Поочерёдно напрягайте и расслабляйте группы мышц:

1. Начните с **кулаков** — сожмите на 5 секунд, расслабьте
2. Перейдите к **бицепсам**
3. Затем **плечи**, **спина**, **пресс**
4. Закончите **ногами** и **ступнями**

## Когнитивная реструктуризация

Записывайте негативные мысли и оспаривайте их:

| Автоматическая мысль | Реальность |
|---|---|
| "У меня ничего не получится" | "Раньше я справлялся с трудностями" |
| "Все против меня" | "Есть люди, которые меня поддерживают" |

## Когда обращаться за помощью

Если стресс мешает повседневной жизни более **2 недель**, обратитесь к специалисту.

---
*На основе методов когнитивно-поведенческой терапии*''',
      'category': 'stress',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['stress'],
    },
    {
      'id': 'local_self_esteem',
      'user_id': null,
      'title': 'Как повысить самооценку: 7 шагов',
      'content': '''## Что такое самооценка

**Самооценка** — это то, как мы оцениваем себя, свои качества и возможности. Здоровая самооценка — основа ментального благополучия.

## 7 практических шагов

### 1. Отслеживайте внутреннего критика
Замечайте негативные мысли о себе. Запишите их и спросите: *"Это факт или моё мнение?"*

### 2. Практикуйте самосострадание
Относитесь к себе так, как относились бы к **другу** в трудной ситуации.

### 3. Отмечайте достижения
Каждый вечер записывайте **3 вещи**, которыми вы гордитесь сегодня. Даже маленькие.

### 4. Установите границы
Научитесь говорить **«нет»** тому, что истощает вас.

### 5. Перестаньте сравнивать себя с другими
Социальные сети показывают только «лучшую» сторону жизни других людей.

### 6. Заботьтесь о теле
- Регулярная физическая активность
- Здоровое питание
- Достаточно сна

### 7. Окружите себя поддерживающими людьми
Минимизируйте общение с теми, кто вас обесценивает.

> **Помните:** Самооценка — это навык, который можно развить. Это не фиксированная черта.

---
*На основе работ Кристин Нефф о самосострадании*''',
      'category': 'self-esteem',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['self-esteem'],
    },
    {
      'id': 'local_mindfulness',
      'user_id': null,
      'title': 'Осознанность для начинающих',
      'content': '''## Что такое осознанность

**Осознанность (mindfulness)** — это способность присутствовать в текущем моменте, замечать свои мысли, чувства и ощущения без осуждения.

## Простая медитация на 5 минут

### Инструкция

1. Сядьте удобно, спина прямая
2. Закройте глаза или опустите взгляд
3. Сосредоточьтесь на **дыхании**
4. Замечайте, как воздух входит и выходит
5. Когда ум блуждает — мягко верните внимание к дыханию
6. Начните с **5 минут**, постепенно увеличивая

## Осознанность в повседневности

### Осознанное питание
- Ешьте медленно
- Замечайте вкус, текстуру, запах каждого кусочка
- Отложите приборы между кусочками

### Осознанная ходьба
- Замечайте, как стопы касаются земли
- Ощущайте вес тела
- Замечайте движение воздуха на коже

### Осознанное слушание
- Слушайте звуки вокруг без оценки
- Замечайте тишину между звуками
- Не пытайтесь интерпретировать

## Научные данные

Исследования показывают, что регулярная практика осознанности:

- Снижает уровень **кортизола** на 25%
- Улучшает концентрацию внимания
- Уменьшает симптомы тревоги и депрессии
- Повышает качество сна

> **«Вы не можете остановить волны, но вы можете научиться сёрфингу»** — Джон Кабат-Зинн

---
*На основе программы MBSR Джона Кабат-Зинна*''',
      'category': 'mindfulness',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['mindfulness'],
    },
  ];
}

/// POST /articles — создать статью
Future<Response> _createArticle(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final title = body['title'] as String?;
  final content = body['content'] as String?;
  final category = body['category'] as String? ?? 'custom';

  if (title == null || title.isEmpty || content == null || content.isEmpty) {
    return Response(statusCode: 400, body: 'title and content are required');
  }

  try {
    final articleId = const Uuid().v4();
    final titleSql = title.replaceAll("'", "''");
    final contentSql = content.replaceAll("'", "''");
    final categorySql = category.replaceAll("'", "''");

    final result = await _db!.query(
      "INSERT INTO articles (id, user_id, title, content, category, is_custom) VALUES ('$articleId', '$userId', '$titleSql', '$contentSql', '$categorySql', true) RETURNING id, user_id, title, content, category, is_custom, source, tags, created_at",
    );

    final row = result.first;
    return Response.json(
      statusCode: 201,
      body: {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
        'title': row[2],
        'content': row[3],
        'category': row[4],
        'is_custom': row[5],
        'source': row[6],
        'tags': row[7],
        'created_at': row[8].toString(),
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// PUT /articles/{id} — обновить статью
Future<Response> _updateArticle(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final title = body['title'] as String?;
  final content = body['content'] as String?;
  final category = body['category'] as String?;

  if (title == null && content == null && category == null) {
    return Response(statusCode: 400, body: 'At least one field must be provided');
  }

  try {
    final titleSql = title != null ? "'${title.replaceAll("'", "''")}'" : null;
    final contentSql = content != null ? "'${content.replaceAll("'", "''")}'" : null;
    final categorySql = category != null ? "'${category.replaceAll("'", "''")}'" : null;

    // Проверяем, что статья принадлежит пользователю
    final checkResult = await _db!.query(
      "SELECT title, content, category FROM articles WHERE id = '$id' AND user_id = '$userId'",
    );

    if (checkResult.isEmpty) {
      return Response(statusCode: 404, body: 'Article not found or not owned by user');
    }

    final currentRow = checkResult.first;
    final finalTitle = titleSql ?? "'${(currentRow[0] as String).replaceAll("'", "''")}'";
    final finalContent = contentSql ?? "'${(currentRow[1] as String).replaceAll("'", "''")}'";
    final finalCategory = categorySql ?? "'${(currentRow[2] as String).replaceAll("'", "''")}'";

    final result = await _db!.query(
      "UPDATE articles SET title = $finalTitle, content = $finalContent, category = $finalCategory WHERE id = '$id' AND user_id = '$userId' RETURNING id, user_id, title, content, category, is_custom, source, tags, created_at",
    );

    final row = result.first;
    return Response.json(body: {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
      'title': row[2],
      'content': row[3],
      'category': row[4],
      'is_custom': row[5],
      'source': row[6],
      'tags': row[7],
      'created_at': row[8].toString(),
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// DELETE /articles/{id} — удалить статью
Future<Response> _deleteArticle(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final result = await _db!.query(
      "DELETE FROM articles WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Article not found or not owned by user');
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
