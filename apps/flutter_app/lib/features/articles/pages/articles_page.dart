import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';
import 'article_detail_page.dart';
import 'create_edit_article_page.dart';

class ArticlesPage extends StatefulWidget {
  final bool showBackButton;

  const ArticlesPage({super.key, this.showBackButton = true});

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
                    icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: const Text(
              'Статьи самопомощи',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.citrusOrange),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateEditArticlePage(),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Поиск статей...',
                    hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.mutedForeground),
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
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat['value'] as String),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.citrusOrange.withOpacity(0.2)
                                : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
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
                              const SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                                  fontSize: 13,
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

              const SizedBox(height: 8),

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
      return const Center(
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ArticleBloc>().add(const LoadArticles()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.citrusOrange,
                foregroundColor: AppColors.primaryForeground,
              ),
              child: const Text('Повторить'),
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
              const SizedBox(height: 16),
              Text(
                hasFilters ? 'Ничего не найдено' : 'Статей пока нет',
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters
                    ? 'Попробуйте изменить фильтры'
                    : 'Создайте свою первую статью',
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
              if (!hasFilters) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateEditArticlePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Создать статью'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Найдено: ${filteredArticles.length}',
              style: const TextStyle(
                color: AppColors.dimForeground,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: articlesByCategory.length,
              itemBuilder: (context, index) {
                final category = articlesByCategory.keys.elementAt(index);
                final articles = articlesByCategory[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: AppColors.citrusAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getCategoryName(category),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${articles.length}',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 12,
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
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _confirmDelete(BuildContext context, Article article) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Удалить статью?', style: TextStyle(color: AppColors.foreground)),
        content: Text(
          'Вы уверены, что хотите удалить "${article.title}"?',
          style: const TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ArticleBloc>().add(DeleteArticle(article.id));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Удалить'),
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

  const _ArticleCard({
    required this.article,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.citrusPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 10, color: AppColors.citrusPurple),
                          SizedBox(width: 3),
                          Text(
                            'Wikipedia',
                            style: TextStyle(
                              color: AppColors.citrusPurple,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (article.isCustom)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.citrusOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 10, color: AppColors.citrusOrange),
                          SizedBox(width: 3),
                          Text(
                            'Пользовательская',
                            style: TextStyle(
                              color: AppColors.citrusOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (article.tags != null && article.tags!.isNotEmpty)
                    ...article.tags!.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getCategoryName(tag),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )),
                ],
              ),
              const SizedBox(height: 8),

              // Заголовок
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (article.isCustom) ...[
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        color: AppColors.mutedForeground,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 12),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        color: AppColors.destructive,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.content.length > 120
                    ? '${article.content.substring(0, 120)}...'
                    : article.content,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Создано: ${_formatDate(article.createdAt)}',
                style: const TextStyle(
                  color: AppColors.dimForeground,
                  fontSize: 12,
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
}
