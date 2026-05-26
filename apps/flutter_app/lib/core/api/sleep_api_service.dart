import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/sleep_record.dart';
import '../config/api_config.dart';

/// API сервис для работы с трекером сна
class SleepApiService {
  final String baseUrl;
  final http.Client _client;
  final String? _token;

  SleepApiService({
    String? baseUrl,
    http.Client? client,
    String? token,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Получить записи сна за период
  Future<List<SleepRecord>> getSleepRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, String>{'user_id': userId};
    if (startDate != null) {
      params['start_date'] = _formatDate(startDate);
    }
    if (endDate != null) {
      params['end_date'] = _formatDate(endDate);
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/sleep/records').replace(queryParameters: params),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => SleepRecord.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Ошибка загрузки записей сна: ${response.statusCode}');
    }
  }

  /// Создать запись сна
  Future<SleepRecord> createSleepRecord(SleepRecord record) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/sleep/records'),
      headers: _headers,
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode == 201) {
      return SleepRecord.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка создания записи сна: ${response.statusCode}');
    }
  }

  /// Обновить запись сна
  Future<SleepRecord> updateSleepRecord(SleepRecord record) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/sleep/records/${record.id}'),
      headers: _headers,
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode == 200) {
      return SleepRecord.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка обновления записи сна: ${response.statusCode}');
    }
  }

  /// Удалить запись сна
  Future<void> deleteSleepRecord(String recordId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/sleep/records/$recordId'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления записи сна: ${response.statusCode}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _client.close();
  }
}
