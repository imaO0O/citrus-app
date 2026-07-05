import 'package:flutter/material.dart';
import '../../core/api/test_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'test_taking_screen.dart';
import '../../core/utils/app_size.dart';
import '../../core/widgets/citrus_card.dart';
import '../../core/widgets/citrus_empty_state.dart';

class TestsListScreen extends StatefulWidget {
  final String? token;

  TestsListScreen({super.key, this.token});

  @override
  State<TestsListScreen> createState() => _TestsListScreenState();
}

class _TestsListScreenState extends State<TestsListScreen> {
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory = 'all';
  Map<String, DateTime> _lastTaken = {};

  static const _categories = {
    'all': 'Все тесты',
    'personality': 'Личность',
    'clinical': 'Клинические',
    'behavioral': 'Поведенческие',
  };

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final api = TestApiService(token: widget.token);
      final tests = await api.getAvailableTests();
      // Подтягиваем последние прохождения (для бейджа «Пройден»)
      final lastTaken = <String, DateTime>{};
      try {
        final results = await api.getTestResults();
        for (final r in results) {
          final id = r['testId']?.toString();
          final d = DateTime.tryParse(r['completedAt']?.toString() ?? '');
          // results отсортированы по дате DESC → первое вхождение = последнее прохождение
          if (id != null && d != null && !lastTaken.containsKey(id)) {
            lastTaken[id] = d;
          }
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _lastTaken = lastTaken;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _relativeDate(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'сегодня';
    if (days == 1) return 'вчера';
    if (days < 7) return '$days дн. назад';
    if (days < 30) return '${(days / 7).floor()} нед. назад';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  List<Map<String, dynamic>> get _filteredTests {
    if (_selectedCategory == 'all') return _tests;
    return _tests.where((t) => t['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Психологические тесты',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: AppSize.s(20),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.citrusOrange),
            )
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    // Категории
                    _buildCategories(),
                    // Список тестов
                    Expanded(child: _buildTestsList()),
                  ],
                ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSize.paddingH(20, 8),
        children: _categories.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: AppSize.paddingOnly(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = entry.key);
              },
              backgroundColor: AppColors.card,
              selectedColor: AppColors.citrusOrange.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.citrusOrange : AppColors.dimForeground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return CitrusEmptyState(
      title: 'Не удалось загрузить',
      subtitle: 'Проверь соединение с интернетом и попробуй снова.',
      actionLabel: 'Повторить',
      actionIcon: Icons.refresh,
      onAction: _loadTests,
    );
  }

  Widget _buildTestsList() {
    final tests = _filteredTests;
    if (tests.isEmpty) {
      return CitrusEmptyState(
        title: 'Пока пусто',
        subtitle: 'В этой категории ещё нет тестов. Загляни в другие разделы.',
      );
    }

    return ListView.builder(
      padding: AppSize.padding(20),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        return _buildTestCard(test);
      },
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final categoryColors = {
      'personality': Color(0xFF8BC34A),
      'clinical': Color(0xFFFF5B5B),
      'behavioral': Color(0xFF2196F3),
    };

    final categoryLabels = {
      'personality': 'Личность',
      'clinical': 'Клинический',
      'behavioral': 'Поведенческий',
    };

    final accentColor = categoryColors[test['category']] ?? AppColors.mutedForeground;
    final categoryLabel = categoryLabels[test['category']] ?? 'Тест';

    return Padding(
      padding: AppSize.paddingOnly(bottom: 12),
      child: CitrusCard(
        accent: accentColor,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestTakingScreen(
                testId: test['id'] as String,
                token: widget.token,
              ),
            ),
          );
          _loadTests(); // обновляем «Пройден» после возврата
        },
        child: Row(
          children: [
            // Иконка
            Container(
              width: AppSize.s(56),
              height: AppSize.s(56),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor.withValues(alpha: 0.22), accentColor.withValues(alpha: 0.08)],
                ),
                borderRadius: AppSize.radius(14),
              ),
              child: Center(
                child: Text(
                  test['icon'] as String,
                  style: TextStyle(fontSize: AppSize.s(28)),
                ),
              ),
            ),
            AppSize.gapW(12),
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'] as String, style: AppText.cardTitle),
                  AppSize.gapH(4),
                  Text(
                    test['description'] as String,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSize.gapH(8),
                  Row(
                    children: [
                      // Бейдж категории
                      Container(
                        padding: AppSize.paddingH(8, 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: AppSize.radius(8),
                        ),
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            fontSize: AppSize.s(10),
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      AppSize.gapW(8),
                      // Количество вопросов и время — занимают оставшееся место
                      Expanded(
                        child: Text(
                          '${test['questionsCount']} вопр. · ~${test['durationMinutes']} мин',
                          style: TextStyle(
                            fontSize: AppSize.s(10),
                            color: AppColors.dimForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_lastTaken[test['id']] != null) ...[
                    AppSize.gapH(8),
                    Row(children: [
                      Icon(Icons.check_circle, size: AppSize.s(13), color: AppColors.citrusGreen),
                      AppSize.gapW(4),
                      Text(
                        'Пройден · ${_relativeDate(_lastTaken[test['id']]!)}',
                        style: TextStyle(fontSize: AppSize.s(11), color: AppColors.citrusGreen, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.dimForeground,
              size: AppSize.s(24),
            ),
          ],
        ),
      ),
    );
  }
}
