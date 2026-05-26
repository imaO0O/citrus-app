import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

// Создаем HttpClient с отключённой проверкой SSL для GigaChat API
HttpClient _createHttpClient() {
  final client = HttpClient();
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return client;
}

final _httpClient = _createHttpClient();

/// Поддерживаемые модели GigaChat
enum GigaChatModel {
  /// Базовая модель (по умолчанию)
  gigachat('GigaChat'),
  
  /// Продвинутая модель для сложных задач
  gigaChatPro('GIGA_CHAT_PRO'),
  
  /// Модель для максимально сложных задач
  gigaChatMax('GIGA_CHAT_MAX');

  final String value;
  const GigaChatModel(this.value);
}

/// Сервис для работы с GigaChat API
class GigaChatService {
  // URL для авторизации GigaChat
  static const _authUrl = 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';

  // URL для чата (базовый)
  static const _chatApiUrl = 'https://gigachat.devices.sberbank.ru/api/v1/chat/completions';

  // Токен авторизации (кэшируется)
  String? _accessToken;
  DateTime? _tokenExpiryTime;

  // Authorization key из личного кабинета (уже base64)
  final String _authorizationKey;

  // ID сессии для кэширования контекста
  final String _sessionId;

  GigaChatService({
    String? authorizationKey,
    String? sessionId,
  })  : _authorizationKey = authorizationKey ?? 'MDE5ZDhiMjEtZDVhOC03MTNlLWEzZGMtNjA1OGQ1Yjc5MGVmOjgzZTUyZDBiLWZhZGItNGZiNi04M2U3LTAxNjBhMDRlODlmZg==',
        _sessionId = sessionId ?? const Uuid().v4();
  
  /// Получить токен авторизации
  Future<String> _getAccessToken() async {
    // Если токен ещё действителен, возвращаем его
    if (_accessToken != null && _tokenExpiryTime != null) {
      if (DateTime.now().isBefore(_tokenExpiryTime!)) {
        return _accessToken!;
      }
    }

    // Получаем новый токен
    try {
      final rqUid = const Uuid().v4();
      final body = 'scope=GIGACHAT_API_PERS';

      final request = await _httpClient.postUrl(Uri.parse(_authUrl));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Authorization', 'Basic $_authorizationKey');
      request.headers.set('RqUID', rqUid);
      request.headers.set('Content-Length', body.length.toString());
      request.write(body);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _accessToken = data['access_token'] as String;
        final expiresIn = data['expires_at'] as int?;

        if (expiresIn != null) {
          _tokenExpiryTime = DateTime.now().add(
            Duration(seconds: expiresIn - 30),
          );
        } else {
          _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 29));
        }

        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode} $responseBody');
      }
    } catch (e) {
      throw Exception('Ошибка при получении токена GigaChat: $e');
    }
  }
  
  /// Принудительно обновить токен (сбросить кэш и получить новый)
  Future<void> _refreshToken() async {
    _accessToken = null;
    _tokenExpiryTime = null;
    await _getAccessToken();
  }

  /// Отправить сообщение в GigaChat и получить ответ
  ///
  /// [messages] - список сообщений в формате:
  /// ```
  /// [
  ///   {'role': 'system', 'content': 'Ты полезный ассистент'},
  ///   {'role': 'user', 'content': 'Привет!'},
  /// ]
  /// ```
  ///
  /// [model] - модель для генерации ответа (по умолчанию GigaChat)
  /// [temperature] - креативность ответов (0.0 - 1.0)
  /// [maxTokens] - максимальное количество токенов в ответе
  /// [retryOnAuthError] - повторить запрос при ошибке 401 (внутренний параметр)
  Future<String> sendMessage(
    List<Map<String, dynamic>> messages, {
    GigaChatModel model = GigaChatModel.gigachat,
    double temperature = 0.7,
    int maxTokens = 1024,
    bool retryOnAuthError = true,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = {
        'model': model.value,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };

      final body = jsonEncode(requestBody);
      final bodyBytes = utf8.encode(body);
      final request = await _httpClient.postUrl(Uri.parse(_chatApiUrl));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Accept', 'application/json');
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('X-Session-ID', _sessionId);
      request.headers.set('Content-Length', bodyBytes.length.toString());
      request.add(bodyBytes);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final choices = data['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          return message['content'] as String;
        } else {
          throw Exception('Нет ответа от GigaChat');
        }
      } else if (response.statusCode == 401) {
        // Токен истёк, пробуем обновить и повторить запрос
        if (retryOnAuthError) {
          print('GigaChat: токен истёк (401), обновляем...');
          await _refreshToken();
          print('GigaChat: токен обновлён, повторяем запрос...');
          // Рекурсивный вызов без retry, чтобы избежать бесконечного цикла
          return sendMessage(
            messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
            retryOnAuthError: false,
          );
        } else {
          throw Exception('GigaChat API error: 401 - Token has expired (повторная попытка не удалась)');
        }
      } else {
        throw Exception(
          'GigaChat API error: ${response.statusCode} $responseBody',
        );
      }
    } catch (e) {
      throw Exception('Ошибка при отправке сообщения в GigaChat: $e');
    }
  }
  
  /// Простой метод для отправки одного сообщения и получения ответа
  Future<String> chat(
    String userMessage, {
    String systemPrompt = 'Ты полезный ассистент по имени Цитрус. Ты помогаешь пользователям следить за своим ментальным здоровьем, даёшь советы по улучшению настроения, борьбе с тревогой и поддержанию хорошего эмоционального состояния. Отвечай дружелюбно и поддерживающе.',
    GigaChatModel model = GigaChatModel.gigachat,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ];

    return sendMessage(
      messages.cast<Map<String, dynamic>>(),
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
