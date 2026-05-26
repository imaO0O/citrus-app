import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../../../core/utils/app_size.dart';

class ArticleDetailPage extends StatelessWidget {
  final Article article;
  final bool showBackButton;

  ArticleDetailPage({
    super.key,
    required this.article,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.foreground),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
        title: Text(
          article.title.length > 40
              ? '${article.title.substring(0, 40)}...'
              : article.title,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: AppSize.s(18),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (article.source == 'wikipedia')
            Padding(
              padding: AppSize.paddingOnly(right: 8),
              child: Container(
                padding: AppSize.paddingH(8, 4),
                decoration: BoxDecoration(
                  color: AppColors.citrusPurple.withOpacity(0.2),
                  borderRadius: AppSize.radius(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, size: 12, color: AppColors.citrusPurple),
                    AppSize.gapW(4),
                    Text(
                      'Wikipedia',
                      style: TextStyle(
                        color: AppColors.citrusPurple,
                        fontSize: AppSize.s(11),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (article.isCustom)
            Padding(
              padding: AppSize.paddingOnly(right: 8),
              child: Container(
                padding: AppSize.paddingH(8, 4),
                decoration: BoxDecoration(
                  color: AppColors.citrusOrange.withOpacity(0.2),
                  borderRadius: AppSize.radius(8),
                ),
                child: Text(
                  'Кастомная',
                  style: TextStyle(
                    color: AppColors.citrusOrange,
                    fontSize: AppSize.s(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: AppSize.padding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория
          Container(
            padding: AppSize.paddingH(12, 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: AppSize.radius(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(article.category),
                  color: AppColors.accent,
                  size: 16,
                ),
                AppSize.gapW(6),
                Text(
                  _getCategoryName(article.category),
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: AppSize.s(13),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppSize.gapH(16),

          // Заголовок
          Text(
            article.title,
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: AppSize.s(26),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          AppSize.gapH(12),

          // Дата создания
          Text(
            'Опубликовано: ${_formatDate(article.createdAt)}',
            style: TextStyle(
              color: AppColors.dimForeground,
              fontSize: AppSize.s(13),
            ),
          ),

          // Теги
          if (article.tags != null && article.tags!.isNotEmpty) ...[
            AppSize.gapH(12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: article.tags!
                  .map((tag) => Container(
                        padding: AppSize.paddingH(10, 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: AppSize.radius(12),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(tag), size: 12, color: AppColors.accent),
                            AppSize.gapW(4),
                            Text(
                              _getCategoryName(tag),
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: AppSize.s(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],

          Divider(color: AppColors.border, height: 32),

          // Markdown контент
          MarkdownBody(
            data: article.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: AppSize.s(16),
                height: 1.7,
              ),
              h1: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(24),
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              h2: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(20),
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              h3: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(18),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              h4: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(16),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              h5: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(15),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              h6: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(14),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              strong: TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.bold,
              ),
              em: TextStyle(
                color: AppColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
              blockquote: TextStyle(
                color: AppColors.citrusAmber,
                fontSize: AppSize.s(16),
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              blockquotePadding: AppSize.paddingOnly(left: 16),
              listBullet: TextStyle(
                color: AppColors.citrusOrange,
                fontSize: AppSize.s(16),
              ),
              code: TextStyle(
                color: AppColors.citrusGreen,
                backgroundColor: AppColors.surface2,
                fontSize: AppSize.s(14),
              ),
              codeblockDecoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: AppSize.radius(8),
              ),
              tableBorder: TableBorder.all(color: AppColors.border),
              tableBody: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
              tableHead: TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.bold,
                fontSize: AppSize.s(14),
              ),
              a: TextStyle(
                color: AppColors.citrusOrange,
                decoration: TextDecoration.underline,
              ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                final url = Uri.parse(href);
                launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'anxiety':
        return 'Тревожность';
      case 'depression':
        return 'Депрессия';
      case 'sleep':
        return 'Сон';
      case 'stress':
        return 'Стресс';
      case 'self-esteem':
        return 'Самооценка';
      case 'relationships':
        return 'Отношения';
      case 'mindfulness':
        return 'Осознанность';
      case 'custom':
        return 'Пользовательские';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'anxiety':
        return Icons.psychology;
      case 'depression':
        return Icons.cloud;
      case 'sleep':
        return Icons.nightlight;
      case 'stress':
        return Icons.self_improvement;
      case 'self-esteem':
        return Icons.favorite;
      case 'relationships':
        return Icons.people;
      case 'mindfulness':
        return Icons.auto_awesome;
      default:
        return Icons.article;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
