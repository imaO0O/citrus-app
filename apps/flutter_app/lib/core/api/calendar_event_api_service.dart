import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/calendar_event.dart';

/// API сервис для работы с событиями календаря
class CalendarEventApiService {
  final String baseUrl;
  final http.Client _client;
  final String? _token;

  CalendarEventApiService({
    this.baseUrl = 'http://192.168.0.102:8081',
    http.Client? client,
    String? token,
  })  : _client = client ?? http.Client(),
        _token = token {
    print('CalendarEventApiService: создан с token=${token != null ? "length=${token.length}" : "null"}');
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      print('CalendarEventApiService: добавлен токен в заголовок (length=${_token!.length})');
    } else {
      print('CalendarEventApiService: токен НЕ добавлен (_token=$_token)');
    }
    print('CalendarEventApiService: заголовки: $headers');
    return headers;
  }

  /// Получить события за месяц
  Future<List<CalendarEventModel>> getEventsForMonth({
    required String userId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    print('CalendarEventApiService: запрос событий для userId=$userId, ${_formatDate(startOfMonth)} - ${_formatDate(endOfMonth)}');

    final response = await _client.get(
      Uri.parse('$baseUrl/calendar/events').replace(queryParameters: {
        'user_id': userId,
        'start_date': _formatDate(startOfMonth),
        'end_date': _formatDate(endOfMonth),
      }),
      headers: _headers,
    );

    print('CalendarEventApiService: статус ${response.statusCode}, тело: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      print('CalendarEventApiService: получено ${jsonList.length} событий');
      return jsonList.map((json) => CalendarEventModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Ошибка загрузки событий: ${response.statusCode}');
    }
  }

  /// Создать событие
  Future<CalendarEventModel> createEvent(CalendarEventModel event) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/calendar/events'),
      headers: _headers,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 201) {
      return CalendarEventModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка создания события: ${response.statusCode}');
    }
  }

  /// Обновить событие
  Future<CalendarEventModel> updateEvent(CalendarEventModel event) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/calendar/events/${event.id}'),
      headers: _headers,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 200) {
      return CalendarEventModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка обновления события: ${response.statusCode}');
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/calendar/events/$eventId'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления события: ${response.statusCode}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _client.close();
  }
}
