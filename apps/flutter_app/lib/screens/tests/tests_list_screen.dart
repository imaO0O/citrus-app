import 'package:flutter/material.dart';
import '../../core/api/test_api_service.dart';
import 'test_taking_screen.dart';

class TestsListScreen extends StatefulWidget {
  final String? token;

  const TestsListScreen({super.key, this.token});

  @override
  State<TestsListScreen> createState() => _TestsListScreenState();
}

class _TestsListScreenState extends State<TestsListScreen> {
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory = 'all';

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
      setState(() {
        _tests = tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTests {
    if (_selectedCategory == 'all') return _tests;
    return _tests.where((t) => t['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'Психологические тесты',
          style: TextStyle(
            color: Color(0xFFEDE8E0),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: _categories.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = entry.key);
              },
              backgroundColor: const Color(0xFF1A1A2E),
              selectedColor: const Color(0xFFFF8C42).withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF8C42) : const Color(0xFF5A5468),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF5B5B)),
          const SizedBox(height: 16),
          Text('Ошибка: $_error',
              style: const TextStyle(color: Color(0xFFEDE8E0))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTests,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    final tests = _filteredTests;
    if (tests.isEmpty) {
      return const Center(
        child: Text(
          'Нет тестов в этой категории',
          style: TextStyle(color: Color(0xFF5A5468)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        return _buildTestCard(test);
      },
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final categoryColors = {
      'personality': const Color(0xFF8BC34A),
      'clinical': const Color(0xFFFF5B5B),
      'behavioral': const Color(0xFF2196F3),
    };

    final categoryLabels = {
      'personality': 'Личность',
      'clinical': 'Клинический',
      'behavioral': 'Поведенческий',
    };

    final accentColor = categoryColors[test['category']] ?? const Color(0xFF8A8298);
    final categoryLabel = categoryLabels[test['category']] ?? 'Тест';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TestTakingScreen(
                  testId: test['id'] as String,
                  token: widget.token,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Иконка
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      test['icon'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDE8E0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8298),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Бейдж категории
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoryLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Количество вопросов
                          Text(
                            '${test['questionsCount']} вопросов',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5A5468),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Время
                          Text(
                            '~${test['durationMinutes']} мин',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF5A5468),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF5A5468),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
