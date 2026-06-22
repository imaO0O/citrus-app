import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';
import '../../data/tests/tests.dart';
import '../../core/api/test_api_service.dart';
import '../../core/services/test_scoring_service.dart';
import '../../core/theme/app_colors.dart';
import 'test_result_screen.dart';
import '../../core/utils/app_size.dart';

class TestTakingScreen extends StatefulWidget {
  final String testId;
  final String? token;

  TestTakingScreen({
    super.key,
    required this.testId,
    this.token,
  });

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  late PsychologicalTest _test;
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _test = TestRegistry.getTest(widget.testId)!;
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[_test.questions[_currentQuestion].id] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _test.questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      _submitTest();
    }
  }

  void _prevQuestion() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  Future<void> _submitTest() async {
    setState(() => _isSubmitting = true);

    try {
      // Подсчёт результатов
      final scores = TestScoringService.calculateScores(widget.testId, _answers);
      final interpretations =
          TestScoringService.getAllInterpretations(widget.testId, scores);

      // Сохранение на сервере (если есть авторизация)
      if (widget.token != null && widget.token!.isNotEmpty) {
        final api = TestApiService(token: widget.token);
        await api.submitTest(
          testId: widget.testId,
          answers: scores,
          interpretations: interpretations.map(
            (k, v) => MapEntry(k, v?.label ?? ''),
          ),
          completedAt: DateTime.now().toIso8601String(),
        );
      }

      // Показ результатов
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultScreen(
            test: _test,
            scores: scores,
            interpretations: interpretations,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _test.questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _test.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.foreground),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.card,
                title: Text('Выйти из теста?',
                    style: TextStyle(color: AppColors.foreground)),
                content: Text(
                  'Прогресс будет потерян. Продолжить?',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  ),
                  TextButton(
                    onPressed: () {
                      // Закрываем диалог, потом выходим на главную
                      Navigator.of(context).pop();
                      // Закрываем экран прохождения теста
                      Navigator.of(context).pop();
                    },
                    child: Text('Выйти',
                        style: TextStyle(color: AppColors.destructive)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          _test.title,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: AppSize.s(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Прогресс-бар
          Padding(
            padding: AppSize.paddingH(20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Вопрос ${_currentQuestion + 1} из ${_test.questions.length}',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: AppSize.s(12),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: AppColors.citrusOrange,
                        fontSize: AppSize.s(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.card,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.citrusOrange,
                  ),
                  minHeight: 6,
                  borderRadius: AppSize.radius(3),
                ),
              ],
            ),
          ),

          AppSize.gapH(24),

          // Вопрос
          Expanded(
            child: SingleChildScrollView(
              padding: AppSize.paddingH(20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: TextStyle(
                      fontSize: AppSize.s(20),
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                      height: 1.4,
                    ),
                  ),
                  AppSize.gapH(32),
                  // Варианты ответов
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _answers[question.id] == index;

                    return Padding(
                      padding: AppSize.paddingOnly(bottom: 12),
                      child: _AnswerOption(
                        text: option,
                        isSelected: isSelected,
                        onTap: () => _selectAnswer(index),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Навигация
          Padding(
            padding: AppSize.padding(20),
            child: Row(
              children: [
                // Назад
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevQuestion,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: BorderSide(color: AppColors.dimForeground),
                        padding: AppSize.paddingH(0, 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSize.radius(12),
                        ),
                      ),
                      child: Text('Назад'),
                    ),
                  ),
                if (_currentQuestion > 0) AppSize.gapW(12),

                // Далее / Завершить
                Expanded(
                  flex: _currentQuestion == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _answers[question.id] != null
                        ? (_isSubmitting ? null : _nextQuestion)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.citrusOrange,
                      foregroundColor: AppColors.primaryForeground,
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentQuestion == _test.questions.length - 1
                                ? 'Завершить'
                                : 'Далее',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  _AnswerOption({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppColors.citrusOrange.withValues(alpha: 0.2)
          : AppColors.card,
      borderRadius: AppSize.radius(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSize.radius(12),
        child: Container(
          padding: AppSize.padding(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? AppColors.citrusOrange
                  : AppColors.foreground.withValues(alpha: 0.05),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppSize.radius(12),
          ),
          child: Row(
            children: [
              // Радио-кнопка
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.citrusOrange
                        : AppColors.dimForeground,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.citrusOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              AppSize.gapW(12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: AppSize.s(14),
                    color: isSelected
                        ? AppColors.citrusOrange
                        : AppColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
