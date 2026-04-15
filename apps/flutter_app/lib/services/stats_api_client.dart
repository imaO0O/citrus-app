import 'dart:convert';
import 'package:http/http.dart' as http;

/// Сервис для получения статистики тестов и упражнений с backend API
class StatsApiClient {
  final String baseUrl;
  final String? token;

  StatsApiClient({
    required this.baseUrl,
    this.token,
  });

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Получить статистику тестов из БД
  Future<int> getTestsCountFromDB() async {
    try {
      final url = Uri.parse('$baseUrl/analytics/stats');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['testsCompleted'] as int;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении статистики тестов: $e');
    }
  }

  /// Получить расширенную статистику упражнений
  Future<Map<String, dynamic>> getExerciseStats() async {
    try {
      final url = Uri.parse('$baseUrl/exercises/stats');
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении статистики упражнений: $e');
    }
  }

  /// Получить историю упражнений
  Future<Map<String, dynamic>> getExercises({
    int limit = 50,
    int offset = 0,
    String? type,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (type != null) 'type': type,
      };
      final url = Uri.parse('$baseUrl/exercises').replace(queryParameters: queryParams);
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка при получении истории упражнений: $e');
    }
  }
}
