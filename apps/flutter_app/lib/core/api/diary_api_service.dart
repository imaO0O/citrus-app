import 'dart:convert';
import 'package:http/http.dart' as http;

class DiaryApiService {
  final String baseUrl;
  final String? _token;
  final http.Client _client;

  DiaryApiService({
    this.baseUrl = 'http://192.168.0.102:8081',
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

  Future<List<Map<String, dynamic>>> getEntries({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (search != null) params['search'] = search;

    final uri = Uri.parse('$baseUrl/diary/entries').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load diary entries: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createEntry({
    required String content,
    int? moodValue,
    String? entryDate,
  }) async {
    final body = {
      'content': content,
      if (moodValue != null) 'mood_value': moodValue,
      if (entryDate != null) 'entry_date': entryDate,
    };

    final response = await _client.post(
      Uri.parse('$baseUrl/diary/entries'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create diary entry: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateEntry({
    required String id,
    required String content,
    int? moodValue,
  }) async {
    final body = {
      'content': content,
      if (moodValue != null) 'mood_value': moodValue,
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/diary/entries/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update diary entry: ${response.statusCode}');
  }

  Future<void> deleteEntry(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/diary/entries/$id'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete diary entry: ${response.statusCode}');
    }
  }
}
