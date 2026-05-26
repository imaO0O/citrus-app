import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для общения с backend API
class ChatApiClient {
  final String baseUrl;
  final String? token;

  ChatApiClient({
    required this.baseUrl,
    this.token,
  });

  /// Отправить сообщение в AI и получить ответ
  Future<String> sendMessage({
    required String message,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/chat');
      
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final body = jsonEncode({
        'message': message,
        if (systemPrompt != null) 'system_prompt': systemPrompt,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Ошибка сервера: ${errorData['error'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при отправке сообщения: $e');
    }
  }
}
