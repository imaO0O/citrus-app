import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/article.dart';
import '../config/api_config.dart';

/// API сервис для работы со статьями самопомощи
class ArticleApiService {
  final String baseUrl;
  final http.Client _client;
  final String? _token;

  ArticleApiService({
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

  /// Получить все статьи (пользователя + системные)
  Future<List<Article>> getArticles() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/articles'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((json) => Article.fromJson(json)).toList();
      } else if (decoded is Map) {
        // На случай если ответ обёрнут
        return [];
      }
      return [];
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Ошибка загрузки статей: ${response.statusCode}');
    }
  }

  /// Создать статью
  Future<Article> createArticle(Article article) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/articles'),
      headers: _headers,
      body: jsonEncode(article.toJson()),
    );

    if (response.statusCode == 201) {
      return Article.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка создания статьи: ${response.statusCode}');
    }
  }

  /// Обновить статью
  Future<Article> updateArticle(Article article) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/articles/${article.id}'),
      headers: _headers,
      body: jsonEncode(article.toJson()),
    );

    if (response.statusCode == 200) {
      return Article.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка обновления статьи: ${response.statusCode}');
    }
  }

  /// Удалить статью
  Future<void> deleteArticle(String articleId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/articles/$articleId'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления статьи: ${response.statusCode}');
    }
  }

  void dispose() {
    _client.close();
  }
}
