import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';
import 'article_detail_page.dart';
import 'create_edit_article_page.dart';
import '../../../core/utils/app_size.dart';

class ArticlesPage extends StatefulWidget {
  final bool showBackButton;

  ArticlesPage({super.key, this.showBackButton = true});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const _categories = [
    {'value': 'all', 'label': 'Все', 'icon': Icons.library_books},
    {'value': 'anxiety', 'label': 'Тревожность', 'icon': Icons.psychology},
    {'value': 'depression', 'label': 'Депрессия', 'icon': Icons.cloud},
    {'value': 'sleep', 'label': 'Сон', 'icon': Icons.nightlight},
    {'value': 'stress', 'label': 'Стресс', 'icon': Icons.self_improvement},
    {'value': 'self-esteem', 'label': 'Самооценка', 'icon': Icons.favorite},
    {'value': 'relationships', 'label': 'Отношения', 'icon': Icons.people},
    {'value': 'mindfulness', 'label': 'Осознанность', 'icon': Icons.auto_awesome},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Article> _filterArticles(List<Article> articles) {
    var filtered = articles;

    // Фильтр по категории
    if (_selectedCategory != 'all') {
      filtered = filtered.where((a) => a.category == _selectedCategory).toList();
    }

    // Фильтр по поиску
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) =>
          a.title.toLowerCase().contains(query) ||
          a.content.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: widget.showBackButton
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.foreground),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: Text(
              'Статьи самопомощи',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(22),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: AppColors.citrusOrange),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateEditArticlePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Поисковая строка
              Padding(
                padding: AppSize.paddingH(16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14)),
                  decoration: InputDecoration(
                    hintText: 'Поиск статей...',
                    hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
                    prefixIcon: Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: AppColors.mutedForeground),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputFieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: AppSize.paddingH(12, 8),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Фильтр по категориям
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: AppSize.paddingH(16, 0),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['value'];
                    return Padding(
                      padding: AppSize.paddingOnly(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['value'] as String),
                        borderRadius: AppSize.radius(20),
                        child: Container(
                          padding: AppSize.paddingH(14, 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.citrusOrange.withValues(alpha: 0.2)
                                : AppColors.surface2,
                            borderRadius: AppSize.radius(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.citrusOrange
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 14,
                                color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                              ),
                              AppSize.gapW(6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                                  fontSize: AppSize.s(13),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              AppSize.gapH(8),

              // Список статей
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ArticleState state) {
    if (state is ArticleLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
        ),
      );
    }

    if (state is ArticleError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
            AppSize.gapH(16),
            Text(
              state.message,
              style: TextStyle(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            AppSize.gapH(16),
            ElevatedButton(
              onPressed: () => context.read<ArticleBloc>().add(LoadArticles()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.citrusOrange,
                foregroundColor: AppColors.primaryForeground,
              ),
              child: Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state is ArticlesLoaded) {
      final filteredArticles = _filterArticles(state.articles);

      if (filteredArticles.isEmpty) {
        final hasFilters = _selectedCategory != 'all' || _searchQuery.isNotEmpty;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFilters ? Icons.filter_list_off : Icons.article_outlined,
                size: 64,
                color: AppColors.mutedForeground,
              ),
              AppSize.gapH(16),
              Text(
                hasFilters ? 'Ничего не найдено' : 'Статей пока нет',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: AppSize.s(18),
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSize.gapH(8),
              Text(
                hasFilters
                    ? 'Попробуйте изменить фильтры'
                    : 'Создайте свою первую статью',
                style: TextStyle(color: AppColors.mutedForeground),
              ),
              if (!hasFilters) ...[
                AppSize.gapH(24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateEditArticlePage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Создать статью'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: AppColors.primaryForeground,
                    padding: AppSize.paddingH(24, 12),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // Группируем статьи по категориям
      final articlesByCategory = <String, List<Article>>{};
      for (final article in filteredArticles) {
        articlesByCategory.putIfAbsent(article.category, () => []).add(article);
      }

      // Показываем количество найденных статей
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSize.paddingOnly(left: 16, bottom: 8),
            child: Text(
              'Найдено: ${filteredArticles.length}',
              style: TextStyle(
                color: AppColors.dimForeground,
                fontSize: AppSize.s(13),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: AppSize.paddingH(16, 0),
              itemCount: articlesByCategory.length,
              itemBuilder: (context, index) {
                final category = articlesByCategory.keys.elementAt(index);
                final articles = articlesByCategory[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: AppSize.paddingOnly(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: AppColors.citrusAmber,
                            size: 20,
                          ),
                          AppSize.gapW(8),
                          Text(
                            _getCategoryName(category),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: AppSize.s(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSize.gapW(8),
                          Container(
                            padding: AppSize.paddingH(8, 2),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: AppSize.radius(12),
                            ),
                            child: Text(
                              '${articles.length}',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: AppSize.s(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...articles.map((article) => _ArticleCard(
                          article: article,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ArticleDetailPage(article: article),
                              ),
                            );
                          },
                          onDelete: article.isCustom
                              ? () => _confirmDelete(context, article)
                              : null,
                          onEdit: article.isCustom
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CreateEditArticlePage(article: article),
                                    ),
                                  );
                                }
                              : null,
                        )),
                    AppSize.gapH(8),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    return SizedBox.shrink();
  }

  void _confirmDelete(BuildContext context, Article article) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Удалить статью?', style: TextStyle(color: AppColors.foreground)),
        content: Text(
          'Вы уверены, что хотите удалить "${article.title}"?',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ArticleBloc>().add(DeleteArticle(article.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: Text('Удалить'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    final cat = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => {'label': category},
    );
    return cat['label'] as String;
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => {'icon': Icons.article},
    );
    return cat['icon'] as IconData;
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  _ArticleCard({
    required this.article,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: AppSize.paddingOnly(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
        child: Padding(
          padding: AppSize.padding(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Метки источника и тегов
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (article.source == 'wikipedia')
                    Container(
                      padding: AppSize.paddingH(6, 2),
                      decoration: BoxDecoration(
                        color: AppColors.citrusPurple.withValues(alpha: 0.2),
                        borderRadius: AppSize.radius(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 10, color: AppColors.citrusPurple),
                          AppSize.gapW(3),
                          Text(
                            'Wikipedia',
                            style: TextStyle(
                              color: AppColors.citrusPurple,
                              fontSize: AppSize.s(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (article.isCustom)
                    Container(
                      padding: AppSize.paddingH(6, 2),
                      decoration: BoxDecoration(
                        color: AppColors.citrusOrange.withValues(alpha: 0.2),
                        borderRadius: AppSize.radius(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 10, color: AppColors.citrusOrange),
                          AppSize.gapW(3),
                          Text(
                            'Пользовательская',
                            style: TextStyle(
                              color: AppColors.citrusOrange,
                              fontSize: AppSize.s(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (article.tags != null && article.tags!.isNotEmpty)
                    ...article.tags!.map((tag) => Container(
                          padding: AppSize.paddingH(6, 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: AppSize.radius(8),
                          ),
                          child: Text(
                            _getCategoryName(tag),
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: AppSize.s(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                ],
              ),
              AppSize.gapH(8),

              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: AppSize.s(16),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (article.isCustom) ...[
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        color: AppColors.mutedForeground,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    AppSize.gapW(12),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        color: AppColors.destructive,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ],
              ),
              AppSize.gapH(8),
              Builder(builder: (_) {
                final preview = _stripMarkdown(article.content);
                return Text(
                  preview.length > 120
                      ? '${preview.substring(0, 120)}...'
                      : preview,
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: AppSize.s(14),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              AppSize.gapH(8),
              Text(
                'Создано: ${_formatDate(article.createdAt)}',
                style: TextStyle(
                  color: AppColors.dimForeground,
                  fontSize: AppSize.s(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _getCategoryName(String category) {
    final categories = {
      'anxiety': 'Тревожность',
      'depression': 'Депрессия',
      'sleep': 'Сон',
      'stress': 'Стресс',
      'self-esteem': 'Самооценка',
      'relationships': 'Отношения',
      'mindfulness': 'Осознанность',
      'custom': 'Пользовательские',
    };
    return categories[category.toLowerCase()] ?? category;
  }

  /// Убирает markdown-разметку, чтобы текст превью статьи выглядел как
  /// обычный текст (без «**», «##», «[…](…)» и т.п.). Покрывает форматирование,
  /// которое встречается в источниках статей.
  String _stripMarkdown(String input) {
    var s = input;
    // Блоки кода ```...``` целиком
    s = s.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Инлайн-код `code`
    s = s.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
    // Картинки ![alt](url) — выкидываем целиком
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '');
    // Ссылки [text](url) → text
    s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1]!);
    // Жирный/курсив: **, __, *, _
    s = s.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1]!);
    s = s.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1]!);
    s = s.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1]!);
    s = s.replaceAllMapped(RegExp(r'(?<!\w)_([^_\n]+)_(?!\w)'), (m) => m[1]!);
    // Зачёркивание
    s = s.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m[1]!);
    // Заголовки, цитаты, маркеры списков в начале строки
    s = s.replaceAll(RegExp(r'^[ \t]*#{1,6}[ \t]+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^[ \t]*>[ \t]?', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^[ \t]*[-*+][ \t]+', multiLine: true), '');
    s = s.replaceAll(RegExp(r'^[ \t]*\d+\.[ \t]+', multiLine: true), '');
    // Горизонтальные разделители
    s = s.replaceAll(
        RegExp(r'^[ \t]*[-*_]{3,}[ \t]*$', multiLine: true), '');
    // Сворачиваем пробелы и переводы строк в один пробел
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }
}
