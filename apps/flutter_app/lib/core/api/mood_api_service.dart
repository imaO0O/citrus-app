import 'dart:convert';
import 'package:http/http.dart' as http;

class MoodApiService {
  final String baseUrl;
  final String? _token;
  final http.Client _client;

  MoodApiService({
    this.baseUrl = 'http://10.0.2.2:8081',
    http.Client? client,
    String? token,
  })  : _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<List<Map<String, dynamic>>> getMoodRecords({
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final uri = Uri.parse('$baseUrl/mood/records').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load mood records: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createMoodRecord({
    required int moodId,
    String? moodDate,
    String? note,
  }) async {
    final body = {
      'mood_id': moodId,
      if (moodDate != null) 'mood_date': moodDate,
      if (note != null) 'note': note,
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/mood/records'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create mood record: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateMoodRecord({
    required String id,
    required int moodId,
    String? note,
  }) async {
    final body = {
      'mood_id': moodId,
      if (note != null) 'note': note,
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/mood/records/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update mood record: ${response.statusCode}');
  }

  Future<void> deleteMoodRecord(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/mood/records/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete mood record: ${response.statusCode}');
    }
  }
}
