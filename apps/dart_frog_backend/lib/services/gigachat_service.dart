import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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

  // Данные для авторизации
  final String _clientId;
  final String _clientSecret;
  
  // ID сессии для кэширования контекта
  final String _sessionId;

  GigaChatService({
    required String clientId,
    required String clientSecret,
    String? sessionId,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
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
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': 'Basic $credentials',
          'RqUID': const Uuid().v4(), // UUID4 формат (обязательно!)
        },
        body: {
          'scope': 'GIGACHAT_API_PERS',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'] as String;
        final expiresIn = data['expires_at'] as int?;
        
        // Устанавливаем время истечения (с запасом 30 секунд)
        if (expiresIn != null) {
          _tokenExpiryTime = DateTime.now().add(
            Duration(seconds: expiresIn - 30),
          );
        } else {
          // По умолчанию 30 минут
          _tokenExpiryTime = DateTime.now().add(const Duration(minutes: 29));
        }
        
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении токена GigaChat: $e');
    }
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
  Future<String> sendMessage(
    List<Map<String, dynamic>> messages, {
    GigaChatModel model = GigaChatModel.gigachat,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = {
        'model': model.value,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };

      final response = await http.post(
        Uri.parse(_chatApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Session-ID': _sessionId, // Для кэширования контекста
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          return message['content'] as String;
        } else {
          throw Exception('Нет ответа от GigaChat');
        }
      } else {
        throw Exception(
          'GigaChat API error: ${response.statusCode} ${response.body}',
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
