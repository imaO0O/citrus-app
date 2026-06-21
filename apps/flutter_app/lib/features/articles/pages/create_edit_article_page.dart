import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';
import '../../../core/utils/app_size.dart';

class CreateEditArticlePage extends StatefulWidget {
  final Article? article;

  CreateEditArticlePage({super.key, this.article});

  @override
  State<CreateEditArticlePage> createState() => _CreateEditArticlePageState();
}

class _CreateEditArticlePageState extends State<CreateEditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  bool _isSaving = false;
  bool _isPreviewMode = false;
  bool _isPublic = false;

  final List<CategoryOption> _categories = [
    CategoryOption(value: 'anxiety', label: 'Тревожность', icon: Icons.psychology),
    CategoryOption(value: 'depression', label: 'Депрессия', icon: Icons.cloud),
    CategoryOption(value: 'sleep', label: 'Сон', icon: Icons.nightlight),
    CategoryOption(value: 'stress', label: 'Стресс', icon: Icons.self_improvement),
    CategoryOption(value: 'self-esteem', label: 'Самооценка', icon: Icons.favorite),
    CategoryOption(value: 'relationships', label: 'Отношения', icon: Icons.people),
    CategoryOption(value: 'mindfulness', label: 'Осознанность', icon: Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController = TextEditingController(text: widget.article?.content ?? '');
    _selectedCategory = widget.article?.category ?? 'anxiety';
    _isPublic = widget.article?.isPublic ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;

    return BlocListener<ArticleBloc, ArticleState>(
      listener: (context, state) {
        if (state is ArticleError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            isEditing ? 'Редактировать статью' : 'Новая статья',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: AppSize.s(18),
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.foreground),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
              color: AppColors.mutedForeground,
            ),
            if (_isSaving)
              Padding(
                padding: AppSize.padding(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
                  ),
                ),
              )
            else
              IconButton(
                icon: Icon(Icons.check, color: AppColors.citrusOrange),
                onPressed: _saveArticle,
              ),
          ],
        ),
        body: _isPreviewMode ? _buildPreview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: AppSize.padding(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Категория
            Text(
              'Категория',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSize.gapH(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category.value;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category.value),
                  borderRadius: AppSize.radius(20),
                  child: Container(
                    padding: AppSize.paddingH(12, 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.citrusOrange.withValues(alpha: 0.2)
                          : AppColors.surface2,
                      borderRadius: AppSize.radius(20),
                      border: Border.all(
                        color: isSelected ? AppColors.citrusOrange : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                        ),
                        AppSize.gapW(6),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                            fontSize: AppSize.s(13),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSize.gapH(24),

            // Заголовок
            Text(
              'Заголовок',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSize.gapH(8),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16)),
              decoration: InputDecoration(
                hintText: 'Введите заголовок статьи...',
                hintStyle: TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.inputFieldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                  borderSide: BorderSide(color: AppColors.citrusOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите заголовок';
                }
                return null;
              },
              maxLength: 200,
              maxLines: 2,
            ),
            AppSize.gapH(24),

            // Содержимое
            Text(
              'Содержание',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: AppSize.s(16),
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSize.gapH(8),
            Text(
              'Поддерживается Markdown разметка: **жирный**, *курсив*, - список, # заголовки',
              style: TextStyle(color: AppColors.dimForeground, fontSize: AppSize.s(12)),
            ),
            AppSize.gapH(8),
            TextFormField(
              controller: _contentController,
              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15)),
              decoration: InputDecoration(
                hintText: 'Напишите статью...',
                hintStyle: TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.inputFieldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                  borderSide: BorderSide(color: AppColors.citrusOrange, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите содержание';
                }
                return null;
              },
              maxLines: 20,
              minLines: 10,
            ),
            AppSize.gapH(24),

            // Публикация в сообщество
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                border: Border.all(
                  color: _isPublic ? AppColors.citrusOrange.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    activeColor: AppColors.citrusOrange,
                    contentPadding: AppSize.paddingH(16, 0),
                    title: Text(
                      'Опубликовать для всех',
                      style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Статья пройдёт модерацию и станет видна в сообществе',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
                    ),
                  ),
                  if (widget.article != null &&
                      widget.article!.isPublic &&
                      widget.article!.moderationStatus != 'private')
                    Padding(
                      padding: AppSize.paddingH(16, 12),
                      child: Row(
                        children: [
                          Icon(_statusIcon(widget.article!.moderationStatus), size: AppSize.s(16), color: _statusColor(widget.article!.moderationStatus)),
                          AppSize.gapW(8),
                          Expanded(
                            child: Text(
                              _statusText(widget.article!.moderationStatus),
                              style: TextStyle(color: _statusColor(widget.article!.moderationStatus), fontSize: AppSize.s(12), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            AppSize.gapH(24),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveArticle,
                icon: Icon(Icons.save),
                label: Text(widget.article != null ? 'Сохранить изменения' : 'Создать статью'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.citrusOrange,
                  foregroundColor: AppColors.primaryForeground,
                  padding: AppSize.paddingH(0, 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSize.s(AppColors.radiusMd)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      return Center(
        child: Text(
          'Начните вводить текст для предпросмотра',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSize.padding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория
          Container(
            padding: AppSize.paddingH(12, 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: AppSize.radius(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categories.firstWhere((c) => c.value == _selectedCategory).icon,
                  color: AppColors.accent,
                  size: 16,
                ),
                AppSize.gapW(6),
                Text(
                  _categories.firstWhere((c) => c.value == _selectedCategory).label,
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
            title.isNotEmpty ? title : 'Без заголовка',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: AppSize.s(26),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          Divider(color: AppColors.border, height: 32),

          // Содержимое
          content.isNotEmpty
              ? MarkdownBody(
                  data: content,
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
                  ),
                )
              : Text(
                  'Нет содержания',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
        ],
      ),
    );
  }

  void _saveArticle() {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.article != null) {
      // Редактирование
      context.read<ArticleBloc>().add(
            UpdateArticle(
              id: widget.article!.id,
              title: title,
              content: content,
              category: _selectedCategory,
              isPublic: _isPublic,
            ),
          );
    } else {
      // Создание
      context.read<ArticleBloc>().add(
            CreateArticle(
              title: title,
              content: content,
              category: _selectedCategory,
              isPublic: _isPublic,
            ),
          );
    }

    // Ждём результат
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isSaving = false);
        // Проверяем, нет ли ошибки
        final state = context.read<ArticleBloc>().state;
        if (state is! ArticleError) {
          Navigator.of(context).pop();
        }
      }
    });
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'approved':
      return Icons.public;
    case 'rejected':
      return Icons.block;
    default:
      return Icons.hourglass_top;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.citrusGreen;
    case 'rejected':
      return AppColors.destructive;
    default:
      return AppColors.citrusAmber;
  }
}

String _statusText(String status) {
  switch (status) {
    case 'approved':
      return 'Опубликовано в сообществе';
    case 'rejected':
      return 'Отклонено модератором. Отредактируйте и сохраните, чтобы отправить снова.';
    default:
      return 'На модерации — ожидает проверки';
  }
}

class CategoryOption {
  final String value;
  final String label;
  final IconData icon;

  CategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
