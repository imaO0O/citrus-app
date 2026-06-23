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

import 'lib/services/gigachat_service.dart';
import 'lib/services/email_service.dart';

part 'handlers/calendar.dart';
part 'handlers/casino.dart';
part 'handlers/diary.dart';
part 'handlers/exercises.dart';
part 'handlers/mood.dart';
part 'handlers/sleep.dart';

part 'handlers/auth.dart';
part 'handlers/content.dart';
part 'handlers/media.dart';
part 'handlers/tests.dart';
part 'handlers/user.dart';

PostgreSQLConnection? _db;
const _jwtSecret = 'citrus-app-secret-key-change-in-production';

/// Email администратора-модератора (видит очередь модерации статей сообщества
/// и одобряет/отклоняет их). Чтобы сменить модератора — поменяйте этот email.
const _adminEmail = 'tsykunova.svetlana05@gmail.com';

// Параметры БД из переменных окружения (с fallback на локальную БД для разработки)
String get _dbHost => Platform.environment['DB_HOST'] ?? 'localhost';
int get _dbPort => int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432;
String get _dbName => Platform.environment['DB_NAME'] ?? 'citrus';
String get _dbUser => Platform.environment['DB_USER'] ?? 'citrus';
String get _dbPassword => Platform.environment['DB_PASSWORD'] ?? 'citrus123';
bool get _dbSSL => Platform.environment['DB_SSL']?.toLowerCase() == 'true' || _dbHost.contains('supabase');

// Ретри при ошибке 42P05 (duplicate_prepared_statement) — коллизия имён
// prepared statements в transaction-mode пулере Supabase (Supavisor).
// При ошибке закрываем соединение, переподключаемся и повторяем запрос.
Future<PostgreSQLResult> _dbQuery(
  String fmtString, {
  Map<String, dynamic>? substitutionValues,
  int? timeoutInSeconds,
}) async {
  try {
    return await _db!.query(
      fmtString,
      substitutionValues: substitutionValues,
      timeoutInSeconds: timeoutInSeconds,
    );
  } catch (e) {
    if (e.toString().contains('42P05') ||
        e.toString().contains('duplicate_prepared_statement')) {
      print('42P05 duplicate_prepared_statement — переподключение и ретри...');
      try {
        await _db!.close();
      } catch (_) {}
      _db = PostgreSQLConnection(
        _dbHost,
        _dbPort,
        _dbName,
        username: _dbUser,
        password: _dbPassword,
        useSSL: _dbSSL,
      );
      await _db!.open();
      return await _db!.query(
        fmtString,
        substitutionValues: substitutionValues,
        timeoutInSeconds: timeoutInSeconds,
      );
    }
    rethrow;
  }
}

// GigaChat сервис
GigaChatService? _gigachatService;

// Cloudinary конфигурация
const _cloudinaryCloudName = 'dgeoniumv';
const _cloudinaryApiKey = '826774537124372';
const _cloudinaryApiSecret = 'dyJlkMFKHKKFJcnDCbDOPfj7fc0';
const _cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/dgeoniumv/image/upload';

const _cacheDurationMinutes = 60;

class _AuthContext {
  String? userId;
  String? email;
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
        _dbHost,
        _dbPort,
        _dbName,
        username: _dbUser,
        password: _dbPassword,
        useSSL: _dbSSL,
      );
      await _db!.open();
      print('Database connected to $_dbHost:$_dbPort/$_dbName! (SSL: $_dbSSL)');
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

  // GET /user/data-export - экспорт всех данных пользователя (JSON)
  if (path == '/user/data-export' && method == HttpMethod.get) {
    return _exportUserData(context);
  }

  // DELETE /user/account - удалить аккаунт и все данные
  if (path == '/user/account' && method == HttpMethod.delete) {
    return _deleteUserAccount(context);
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

  // Casino endpoints
  if (path.startsWith('/casino')) {
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

  // GET /casino/status - получить статус монет
  if (path == '/casino/status' && method == HttpMethod.get) {
    return _getCasinoStatus(context, authContext);
  }

  // POST /casino/daily - получить ежедневные монеты
  if (path == '/casino/daily' && method == HttpMethod.post) {
    return _claimDailyCoins(context, authContext);
  }

  // POST /casino/quest - выполнить задание
  if (path == '/casino/quest' && method == HttpMethod.post) {
    return _completeQuest(context, authContext);
  }

  // POST /casino/spin - спин (ставка)
  if (path == '/casino/spin' && method == HttpMethod.post) {
    return _casinoSpin(context, authContext);
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
      authContext.email = jwt.payload['email'] as String?;
    } catch (e) {
      return Response(statusCode: 401, body: 'Invalid token');
    }
  }

  // GET /articles/moderation — очередь модерации (только админ)
  if (path == '/articles/moderation' && method == HttpMethod.get) {
    return _getModerationQueue(context, authContext);
  }

  // POST /articles/{id}/moderate — одобрить/отклонить (только админ)
  if (path.startsWith('/articles/') && path.endsWith('/moderate') && method == HttpMethod.post) {
    final id = path.substring('/articles/'.length, path.length - '/moderate'.length);
    return _moderateArticle(context, authContext, id);
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

String _getTimeOfDay(String isoDate) {
  final dt = DateTime.parse(isoDate);
  if (dt.hour < 12) return 'morning';
  if (dt.hour < 18) return 'afternoon';
  return 'evening';
}

// ==================== DIARY ENDPOINTS ====================

const _corsHeaders = <String, String>{
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, Accept',
  'Access-Control-Max-Age': '86400',
};

/// Оборачивает обработчик: отвечает на preflight-запросы (OPTIONS) и добавляет
/// CORS-заголовки ко всем ответам, чтобы веб-версия (PWA) могла обращаться к API
/// из браузера. На нативных платформах (Android/iOS) CORS не действует и обёртка
/// не мешает.
Future<Response> _handleWithCors(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204, headers: _corsHeaders);
  }
  final res = await _handleRequest(context);
  final chunks = await res.bytes().toList();
  final bodyBytes = chunks.expand((e) => e).toList();
  return Response.bytes(
    body: bodyBytes,
    statusCode: res.statusCode,
    headers: {...res.headers, ..._corsHeaders},
  );
}

void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8081') ?? 8081;
  final server = await serve(_handleWithCors, InternetAddress.anyIPv4, port);
  print('Server running on http://${server.address.host}:${server.port}');
}

// ==================== PSYCHOLOGICAL TESTS ENDPOINTS ====================

/// GET /analytics/stats - полная статистика активности пользователя
Future<Response> _getAnalyticsStats(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;

  try {
    // Количество сообщений в чате
    int chatMessages = 0;
    try {
      final chatResult = await _dbQuery(
        'SELECT COUNT(*) FROM chat_messages WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
      );
      chatMessages = int.parse(chatResult.first[0].toString());
    } catch (_) {}

    // Количество пройденных тестов
    int testsCompleted = 0;
    try {
      final testResult = await _dbQuery(
        'SELECT COUNT(*) FROM psychological_test_results WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
      );
      testsCompleted = int.parse(testResult.first[0].toString());
    } catch (_) {}

    // Количество выполненных упражнений
    int exercisesCompleted = 0;
    try {
      final exerciseResult = await _dbQuery(
        'SELECT COALESCE(SUM(completion_count), 0) FROM user_exercises WHERE user_id = @userId',
        substitutionValues: {'userId': userId},
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

