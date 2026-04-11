import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TestApiService {
  final String baseUrl;
  final String? _token;
  final http.Client _client;

  TestApiService({
    String? baseUrl,
    http.Client? client,
    String? token,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  /// Получить список всех доступных тестов
  Future<List<Map<String, dynamic>>> getAvailableTests() async {
    final uri = Uri.parse('$baseUrl/tests');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load tests: ${response.statusCode}');
  }

  /// Отправить результаты теста
  Future<Map<String, dynamic>> submitTest({
    required String testId,
    required Map<String, int> answers,
    required Map<String, String> interpretations,
    String? completedAt,
  }) async {
    final body = {
      'answers': answers.map((k, v) => MapEntry(k, v)),
      'interpretations': interpretations,
      if (completedAt != null) 'completedAt': completedAt,
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/tests/$testId/submit'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to submit test: ${response.statusCode}');
  }

  /// Получить историю всех результатов
  Future<List<Map<String, dynamic>>> getTestResults() async {
    final uri = Uri.parse('$baseUrl/tests/results');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load results: ${response.statusCode}');
  }

  /// Получить результаты конкретного теста
  Future<List<Map<String, dynamic>>> getTestResult(String testId) async {
    final uri = Uri.parse('$baseUrl/tests/results/$testId');
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load result: ${response.statusCode}');
  }
}
