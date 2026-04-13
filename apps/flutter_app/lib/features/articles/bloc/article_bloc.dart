import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/article_repository.dart';
import '../../../models/article.dart';

abstract class ArticleEvent {
  const ArticleEvent();
}

class LoadArticles extends ArticleEvent {
  const LoadArticles();
}

class CreateArticle extends ArticleEvent {
  final String title;
  final String content;
  final String category;

  const CreateArticle({
    required this.title,
    required this.content,
    this.category = 'custom',
  });
}

class UpdateArticle extends ArticleEvent {
  final String id;
  final String title;
  final String content;
  final String category;

  const UpdateArticle({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'custom',
  });
}

class DeleteArticle extends ArticleEvent {
  final String id;

  const DeleteArticle(this.id);
}

abstract class ArticleState {
  const ArticleState();
}

class ArticleInitial extends ArticleState {
  const ArticleInitial();
}

class ArticleLoading extends ArticleState {
  const ArticleLoading();
}

class ArticlesLoaded extends ArticleState {
  final List<Article> articles;

  const ArticlesLoaded(this.articles);
}

class ArticleError extends ArticleState {
  final String message;

  const ArticleError(this.message);
}

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleRepository _repository;

  ArticleBloc({required ArticleRepository repository})
      : _repository = repository,
        super(const ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<CreateArticle>(_onCreateArticle);
    on<UpdateArticle>(_onUpdateArticle);
    on<DeleteArticle>(_onDeleteArticle);
  }

  void setToken(String token) {
    _repository.setToken(token);
    add(const LoadArticles());
  }

  Future<void> _onLoadArticles(LoadArticles event, Emitter<ArticleState> emit) async {
    emit(const ArticleLoading());

    try {
      final articles = await _repository.getArticles();
      emit(ArticlesLoaded(articles));
    } catch (e) {
      emit(ArticleError('Ошибка загрузки статей: $e'));
    }
  }

  Future<void> _onCreateArticle(CreateArticle event, Emitter<ArticleState> emit) async {
    try {
      final article = Article(
        id: '',
        title: event.title,
        content: event.content,
        category: event.category,
        isCustom: true,
        createdAt: DateTime.now(),
      );

      await _repository.createArticle(article);
      if (state is ArticlesLoaded) add(const LoadArticles());
    } catch (e) {
      emit(ArticleError('Ошибка создания статьи: $e'));
    }
  }

  Future<void> _onUpdateArticle(UpdateArticle event, Emitter<ArticleState> emit) async {
    try {
      final currentArticles = (state as ArticlesLoaded).articles;
      final existing = currentArticles.firstWhere((a) => a.id == event.id);

      final article = Article(
        id: event.id,
        userId: existing.userId,
        title: event.title,
        content: event.content,
        category: event.category,
        isCustom: true,
        createdAt: existing.createdAt,
      );

      await _repository.updateArticle(article);
      if (state is ArticlesLoaded) add(const LoadArticles());
    } catch (e) {
      emit(ArticleError('Ошибка обновления статьи: $e'));
    }
  }

  Future<void> _onDeleteArticle(DeleteArticle event, Emitter<ArticleState> emit) async {
    try {
      await _repository.deleteArticle(event.id);
      if (state is ArticlesLoaded) add(const LoadArticles());
    } catch (e) {
      emit(ArticleError('Ошибка удаления статьи: $e'));
    }
  }
}
