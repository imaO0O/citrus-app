import '../../../models/article.dart';
import '../../../core/api/article_api_service.dart';

/// Репозиторий для работы со статьями самопомощи
class ArticleRepository {
  ArticleApiService _apiService;

  ArticleRepository({
    String? token,
    ArticleApiService? apiService,
  }) : _apiService = apiService ?? ArticleApiService(token: token);

  /// Обновить токен
  void setToken(String token) {
    _apiService = ArticleApiService(token: token);
  }

  /// Получить все статьи
  Future<List<Article>> getArticles() async {
    return await _apiService.getArticles();
  }

  /// Создать статью
  Future<Article> createArticle(Article article) async {
    return await _apiService.createArticle(article);
  }

  /// Обновить статью
  Future<Article> updateArticle(Article article) async {
    return await _apiService.updateArticle(article);
  }

  /// Удалить статью
  Future<void> deleteArticle(String articleId) async {
    await _apiService.deleteArticle(articleId);
  }
}
