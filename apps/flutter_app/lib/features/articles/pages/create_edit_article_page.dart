import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/article.dart';
import '../bloc/article_bloc.dart';

class CreateEditArticlePage extends StatefulWidget {
  final Article? article;

  const CreateEditArticlePage({super.key, this.article});

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

  final List<CategoryOption> _categories = [
    const CategoryOption(value: 'custom', label: 'Пользовательская', icon: Icons.article),
    const CategoryOption(value: 'anxiety', label: 'Тревожность', icon: Icons.psychology),
    const CategoryOption(value: 'depression', label: 'Депрессия', icon: Icons.cloud),
    const CategoryOption(value: 'sleep', label: 'Сон', icon: Icons.nightlight),
    const CategoryOption(value: 'stress', label: 'Стресс', icon: Icons.self_improvement),
    const CategoryOption(value: 'self-esteem', label: 'Самооценка', icon: Icons.favorite),
    const CategoryOption(value: 'relationships', label: 'Отношения', icon: Icons.people),
    const CategoryOption(value: 'mindfulness', label: 'Осознанность', icon: Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController = TextEditingController(text: widget.article?.content ?? '');
    _selectedCategory = widget.article?.category ?? 'custom';
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
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.foreground),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
              color: AppColors.mutedForeground,
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
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
                icon: const Icon(Icons.check, color: AppColors.citrusOrange),
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
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Категория
            const Text(
              'Категория',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category.value;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category.value),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.citrusOrange.withOpacity(0.2)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
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
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Заголовок
            const Text(
              'Заголовок',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.foreground, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Введите заголовок статьи...',
                hintStyle: const TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.inputFieldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  borderSide: const BorderSide(color: AppColors.citrusOrange, width: 2),
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
            const SizedBox(height: 24),

            // Содержимое
            const Text(
              'Содержание',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Поддерживается Markdown разметка: **жирный**, *курсив*, - список, # заголовки',
              style: TextStyle(color: AppColors.dimForeground, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              style: const TextStyle(color: AppColors.foreground, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Напишите статью...',
                hintStyle: const TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.inputFieldBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  borderSide: const BorderSide(color: AppColors.citrusOrange, width: 2),
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
            const SizedBox(height: 32),

            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveArticle,
                icon: const Icon(Icons.save),
                label: Text(widget.article != null ? 'Сохранить изменения' : 'Создать статью'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.citrusOrange,
                  foregroundColor: AppColors.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
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
      return const Center(
        child: Text(
          'Начните вводить текст для предпросмотра',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Категория
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categories.firstWhere((c) => c.value == _selectedCategory).icon,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _categories.firstWhere((c) => c.value == _selectedCategory).label,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Заголовок
          Text(
            title.isNotEmpty ? title : 'Без заголовка',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const Divider(color: AppColors.border, height: 32),

          // Содержимое
          content.isNotEmpty
              ? SelectableText(
                  content,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 16,
                    height: 1.7,
                  ),
                )
              : const Text(
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
            ),
          );
    } else {
      // Создание
      context.read<ArticleBloc>().add(
            CreateArticle(
              title: title,
              content: content,
              category: _selectedCategory,
            ),
          );
    }

    // Ждём результат
    Future.delayed(const Duration(milliseconds: 500), () {
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

class CategoryOption {
  final String value;
  final String label;
  final IconData icon;

  const CategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
