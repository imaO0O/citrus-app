import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class MemoryPhotoApiService {
  final String baseUrl;
  final String? _token;
  final http.Client _client;

  MemoryPhotoApiService({
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

  /// Получить все фото пользователя
  Future<List<Map<String, dynamic>>> getPhotos() async {
    debugPrint('[MemoryPhotoApiService] GET $baseUrl/photos');
    debugPrint('[MemoryPhotoApiService] Headers: $_headers');
    final response = await _client.get(
      Uri.parse('$baseUrl/photos'),
      headers: _headers,
    );
    debugPrint('[MemoryPhotoApiService] Status: ${response.statusCode}');
    debugPrint('[MemoryPhotoApiService] Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    final errorBody = response.body;
    throw Exception('Failed to load photos: ${response.statusCode} - $errorBody');
  }

  /// Загрузить фото (multipart)
  Future<Map<String, dynamic>> uploadPhoto({
    required Uint8List bytes,
    required String filename,
    String? caption,
    String? photoDate,
  }) async {
    final uri = Uri.parse('$baseUrl/photos');
    final request = http.MultipartRequest('POST', uri);

    // Добавляем заголовок авторизации
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Прикрепляем файл из байтов — работает и на мобильных, и на web.
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    );
    request.files.add(multipartFile);

    // Дополнительные поля
    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }
    if (photoDate != null && photoDate.isNotEmpty) {
      request.fields['photo_date'] = photoDate;
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    }
    throw Exception('Failed to upload photo: ${response.statusCode} $responseBody');
  }

  /// Удалить фото
  Future<void> deletePhoto(String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/photos/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete photo: ${response.statusCode}');
    }
  }

  /// Переключить избранное
  Future<bool> toggleFavorite(String id) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/photos/$id/favorite'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['is_favorite'] as bool;
    }
    throw Exception('Failed to toggle favorite: ${response.statusCode}');
  }
}
