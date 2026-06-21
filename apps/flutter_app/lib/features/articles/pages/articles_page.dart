import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';
import 'article_detail_page.dart';
import 'create_edit_article_page.dart';
import 'moderation_screen.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/utils/app_size.dart';
import '../../../core/utils/article_visuals.dart';
import '../../../core/services/article_prefs_service.dart';

class ArticlesPage extends StatefulWidget {
  final bool showBackButton;
  final String? initialCategory;

  ArticlesPage({super.key, this.showBackButton = true, this.initialCategory});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  late String _selectedCategory = widget.initialCategory ?? 'all';
  String _searchQuery = '';
  bool _onlyFavorites = false;
  final TextEditingController _searchController = TextEditingController();
  final ArticlePrefsService _prefs = ArticlePrefsService();
  Set<String> _favorites = {};
  Set<String> _readIds = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final fav = await _prefs.getFavorites();
    final read = await _prefs.getRead();
    if (mounted) setState(() { _favorites = fav; _readIds = read; });
  }

  Future<void> _toggleFavorite(Article a) async {
    final nowFav = await _prefs.toggleFavorite(a.id);
    if (mounted) {
      setState(() {
        if (nowFav) {
          _favorites.add(a.id);
        } else {
          _favorites.remove(a.id);
        }
      });
    }
  }

  Future<void> _openArticle(Article article) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailPage(article: article)),
    );
    await _prefs.markRead(article.id);
    if (mounted) setState(() => _readIds.add(article.id));
  }

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

    // Только избранное
    if (_onlyFavorites) {
      filtered = filtered.where((a) => _favorites.contains(a.id)).toList();
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
        final auth = context.watch<AuthBloc>().state;
        final isAdmin = auth is AuthAuthenticated && auth.user.isAdmin;
        _currentUserId = auth is AuthAuthenticated ? auth.user.id : null;
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
              if (isAdmin)
                IconButton(
                  icon: Icon(Icons.fact_check_outlined, color: AppColors.citrusOrange),
                  tooltip: 'Модерация',
                  onPressed: () async {
                    final token = auth.user.token;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ModerationScreen(token: token)),
                    );
                    if (mounted) context.read<ArticleBloc>().add(const LoadArticles());
                  },
                ),
              IconButton(
                icon: Icon(
                  _onlyFavorites ? Icons.bookmark : Icons.bookmark_border,
                  color: _onlyFavorites ? AppColors.citrusAmber : AppColors.foreground,
                ),
                tooltip: 'Избранное',
                onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
              ),
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
      return ListView(
        padding: AppSize.padding(16),
        children: List.generate(5, (_) => _buildSkeletonCard()),
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
        final hasFilters = _selectedCategory != 'all' || _searchQuery.isNotEmpty || _onlyFavorites;
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

      // Hero — рекомендуемая статья (только на общем экране без фильтров)
      final showHero = _selectedCategory == 'all' &&
          _searchQuery.isEmpty &&
          !_onlyFavorites &&
          filteredArticles.length > 2;
      final sortedByDate = List<Article>.from(filteredArticles)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final Article? featured = showHero ? sortedByDate.first : null;
      final listArticles = featured == null
          ? filteredArticles
          : filteredArticles.where((a) => a.id != featured.id).toList();

      // Группируем статьи по категориям
      final articlesByCategory = <String, List<Article>>{};
      for (final article in listArticles) {
        articlesByCategory.putIfAbsent(article.category, () => []).add(article);
      }

      return ListView(
        padding: AppSize.paddingH(16, 0),
        children: [
          if (featured != null) ...[
            AppSize.gapH(4),
            _buildHero(featured),
          ],
          Padding(
            padding: AppSize.paddingOnly(top: 8, bottom: 8),
            child: Text(
              'Найдено: ${filteredArticles.length}',
              style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(13)),
            ),
          ),
          ...articlesByCategory.entries.map((entry) {
            final category = entry.key;
            final articles = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppSize.paddingOnly(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(ArticleVisuals.icon(category), color: ArticleVisuals.color(category), size: 20),
                      AppSize.gapW(8),
                      Text(
                        ArticleVisuals.name(category),
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700),
                      ),
                      AppSize.gapW(8),
                      Container(
                        padding: AppSize.paddingH(8, 2),
                        decoration: BoxDecoration(color: AppColors.muted, borderRadius: AppSize.radius(12)),
                        child: Text('${articles.length}', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
                      ),
                    ],
                  ),
                ),
                ...articles.map((article) {
                  final isOwn = article.userId != null && article.userId == _currentUserId;
                  return _ArticleCard(
                    article: article,
                    currentUserId: _currentUserId,
                    isFavorite: _favorites.contains(article.id),
                    isRead: _readIds.contains(article.id),
                    onToggleFavorite: () => _toggleFavorite(article),
                    onTap: () => _openArticle(article),
                    onDelete: (article.isCustom && isOwn) ? () => _confirmDelete(context, article) : null,
                    onEdit: (article.isCustom && isOwn)
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CreateEditArticlePage(article: article)),
                            );
                          }
                        : null,
                  );
                }),
                AppSize.gapH(8),
              ],
            );
          }),
        ],
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildHero(Article article) {
    final color = ArticleVisuals.color(article.category);
    final minutes = ArticleVisuals.readingMinutes(article.content);
    return GestureDetector(
      onTap: () => _openArticle(article),
      child: Container(
        margin: AppSize.paddingOnly(bottom: 4),
        padding: AppSize.padding(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.10)],
          ),
          borderRadius: AppSize.radius(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: AppSize.s(15), color: color),
              AppSize.gapW(6),
              Text('Рекомендуем', style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(ArticleVisuals.icon(article.category), size: AppSize.s(15), color: color),
              AppSize.gapW(5),
              Text(ArticleVisuals.name(article.category), style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w600)),
            ]),
            AppSize.gapH(12),
            Text(
              article.title,
              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(19), fontWeight: FontWeight.w800, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AppSize.gapH(10),
            Row(children: [
              Icon(Icons.schedule, size: AppSize.s(13), color: AppColors.mutedForeground),
              AppSize.gapW(4),
              Text('$minutes мин чтения', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
              const Spacer(),
              Text('Читать →', style: TextStyle(color: color, fontSize: AppSize.s(13), fontWeight: FontWeight.w700)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          margin: AppSize.paddingOnly(bottom: 8),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(6)),
        );
    return Container(
      margin: AppSize.paddingOnly(bottom: 10),
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(AppColors.radiusMd.toDouble()),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(AppSize.s(90), AppSize.s(12)),
          bar(double.infinity, AppSize.s(16)),
          bar(AppSize.s(220), AppSize.s(12)),
          bar(AppSize.s(120), AppSize.s(12)),
        ],
      ),
    );
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

}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isFavorite;
  final bool isRead;
  final VoidCallback onToggleFavorite;
  final String? currentUserId;

  _ArticleCard({
    required this.article,
    required this.onTap,
    required this.isFavorite,
    required this.isRead,
    required this.onToggleFavorite,
    this.currentUserId,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = ArticleVisuals.color(article.category);
    final minutes = ArticleVisuals.readingMinutes(article.content);
    final preview = _stripMarkdown(article.content);
    final isOwn = article.userId != null && article.userId == currentUserId;
    final isCommunity = article.userId != null && !isOwn;
    return Card(
      color: AppColors.card,
      margin: AppSize.paddingOnly(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Цветовой акцент категории
              Container(width: AppSize.s(4), color: color),
              Expanded(
                child: Padding(
                  padding: AppSize.padding(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Категория + прочитано + избранное
                      Row(
                        children: [
                          Icon(ArticleVisuals.icon(article.category), size: AppSize.s(15), color: color),
                          AppSize.gapW(6),
                          Flexible(
                            child: Text(
                              ArticleVisuals.name(article.category),
                              style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRead) ...[
                            AppSize.gapW(8),
                            Icon(Icons.check_circle, size: AppSize.s(13), color: AppColors.citrusGreen),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: onToggleFavorite,
                            behavior: HitTestBehavior.opaque,
                            child: Icon(
                              isFavorite ? Icons.bookmark : Icons.bookmark_border,
                              size: AppSize.s(20),
                              color: isFavorite ? AppColors.citrusAmber : AppColors.dimForeground,
                            ),
                          ),
                        ],
                      ),
                      AppSize.gapH(8),
                      Text(
                        article.title,
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w700, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCommunity) ...[
                        AppSize.gapH(5),
                        Row(children: [
                          Icon(Icons.groups, size: AppSize.s(13), color: AppColors.citrusPurple),
                          AppSize.gapW(4),
                          Flexible(
                            child: Text(
                              'Сообщество · ${article.author ?? 'автор'}',
                              style: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(11), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                      AppSize.gapH(6),
                      Text(
                        preview.length > 110 ? '${preview.substring(0, 110)}...' : preview,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13), height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSize.gapH(10),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: AppSize.s(13), color: AppColors.dimForeground),
                          AppSize.gapW(4),
                          Text('$minutes мин', style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12))),
                          if (isOwn && article.isPublic && article.moderationStatus == 'pending') ...[
                            AppSize.gapW(10),
                            Icon(Icons.hourglass_top, size: AppSize.s(13), color: AppColors.citrusAmber),
                            AppSize.gapW(3),
                            Text('На модерации', style: TextStyle(color: AppColors.citrusAmber, fontSize: AppSize.s(11))),
                          ] else if (isOwn && article.isPublic && article.moderationStatus == 'rejected') ...[
                            AppSize.gapW(10),
                            Icon(Icons.block, size: AppSize.s(13), color: AppColors.destructive),
                            AppSize.gapW(3),
                            Text('Отклонено', style: TextStyle(color: AppColors.destructive, fontSize: AppSize.s(11))),
                          ] else if (isOwn && article.isPublic && article.moderationStatus == 'approved') ...[
                            AppSize.gapW(10),
                            Icon(Icons.public, size: AppSize.s(13), color: AppColors.citrusGreen),
                            AppSize.gapW(3),
                            Text('В сообществе', style: TextStyle(color: AppColors.citrusGreen, fontSize: AppSize.s(11))),
                          ] else if (article.source == 'wikipedia') ...[
                            AppSize.gapW(10),
                            Icon(Icons.language, size: AppSize.s(13), color: AppColors.citrusPurple),
                            AppSize.gapW(3),
                            Text('Wikipedia', style: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(11))),
                          ] else if (isOwn && article.isCustom) ...[
                            AppSize.gapW(10),
                            Icon(Icons.person, size: AppSize.s(13), color: AppColors.citrusOrange),
                            AppSize.gapW(3),
                            Text('Моя', style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(11))),
                          ],
                          const Spacer(),
                          if (article.isCustom && onEdit != null)
                            GestureDetector(
                              onTap: onEdit,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: AppSize.paddingH(6, 4),
                                child: Icon(Icons.edit, size: AppSize.s(17), color: AppColors.mutedForeground),
                              ),
                            ),
                          if (article.isCustom && onDelete != null)
                            GestureDetector(
                              onTap: onDelete,
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: AppSize.paddingH(6, 4),
                                child: Icon(Icons.delete_outline, size: AppSize.s(17), color: AppColors.destructive),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
