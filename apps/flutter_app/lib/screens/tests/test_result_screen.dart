import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';
import '../../core/theme/app_colors.dart';
import 'test_taking_screen.dart';
import '../../core/utils/app_size.dart';

class TestResultScreen extends StatelessWidget {
  final PsychologicalTest test;
  final Map<String, int> scores;
  final Map<String, ScoreInterpretation?> interpretations;
  final String? token;

  TestResultScreen({
    super.key,
    required this.test,
    required this.scores,
    required this.interpretations,
    this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Результаты',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: AppSize.s(20),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () {
            // В стеке: TestsListScreen → TestTakingScreen → TestResultScreen
            // 2 попа: закрываем результат и прохождение → список тестов
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSize.padding(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Center(
              child: Column(
                children: [
                  Text(
                    test.icon,
                    style: TextStyle(fontSize: AppSize.s(64)),
                  ),
                  AppSize.gapH(16),
                  Text(
                    test.title,
                    style: TextStyle(
                      fontSize: AppSize.s(24),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSize.gapH(8),
                  Text(
                    'Завершено ${_formatDate(DateTime.now())}',
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      color: AppColors.dimForeground,
                    ),
                  ),
                ],
              ),
            ),

            AppSize.gapH(32),

            // Результаты по шкалам
            Text(
              'Ваши результаты',
              style: TextStyle(
                fontSize: AppSize.s(18),
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            AppSize.gapH(16),

            ...scores.entries.map((entry) {
              final scale = test.scoringScales[entry.key];
              final interpretation = interpretations[entry.key];
              if (scale == null) return SizedBox.shrink();

              return Padding(
                padding: AppSize.paddingOnly(bottom: 16),
                child: _ScaleResultCard(
                  scale: scale,
                  score: entry.value,
                  interpretation: interpretation,
                ),
              );
            }).toList(),

            AppSize.gapH(24),

            // Дисклеймер
            Container(
              padding: AppSize.padding(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppSize.radius(12),
                border: Border.all(
                  color: AppColors.citrusOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.citrusOrange,
                    size: 24,
                  ),
                  AppSize.gapW(12),
                  Expanded(
                    child: Text(
                      'Этот тест носит информационный характер. Для профессиональной консультации обратитесь к специалисту.',
                      style: TextStyle(
                        fontSize: AppSize.s(12),
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppSize.gapH(24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Пройти снова — заменяем текущий экран на TestTakingScreen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => TestTakingScreen(
                            testId: test.id,
                            token: token,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.replay),
                    label: Text('Пройти снова'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground,
                      side: BorderSide(color: AppColors.dimForeground),
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                  ),
                ),
                AppSize.gapW(12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Закрываем результат и прохождение → список тестов
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.list),
                    label: Text('Все тесты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.citrusOrange,
                      foregroundColor: AppColors.primaryForeground,
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ScaleResultCard extends StatelessWidget {
  final ScoringScale scale;
  final int score;
  final ScoreInterpretation? interpretation;

  _ScaleResultCard({
    required this.scale,
    required this.score,
    required this.interpretation,
  });

  double get _progress {
    final range = scale.maxScore - scale.minScore;
    if (range == 0) return 0;
    return (score - scale.minScore) / range;
  }

  Color get _levelColor {
    switch (interpretation?.level) {
      case 'low':
      case 'normal':
      case 'minimal':
        return Color(0xFF8BC34A);
      case 'medium':
      case 'mild':
        return Color(0xFFFFD93D);
      case 'moderate':
        return AppColors.citrusOrange;
      case 'high':
      case 'severe':
      case 'moderately_severe':
      case 'extremely_severe':
        return AppColors.destructive;
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSize.radius(16),
        border: Border.all(
          color: AppColors.foreground.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название шкалы
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  scale.label,
                  style: TextStyle(
                    fontSize: AppSize.s(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Text(
                '$score / ${scale.maxScore}',
                style: TextStyle(
                  fontSize: AppSize.s(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          AppSize.gapH(12),

          // Прогресс-бар
          ClipRRect(
            borderRadius: AppSize.radius(4),
            child: LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.muted,
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
              minHeight: 8,
            ),
          ),
          AppSize.gapH(12),

          // Уровень
          if (interpretation != null) ...[
            Container(
              padding: AppSize.paddingH(10, 4),
              decoration: BoxDecoration(
                color: _levelColor.withValues(alpha: 0.15),
                borderRadius: AppSize.radius(8),
              ),
              child: Text(
                interpretation!.label,
                style: TextStyle(
                  fontSize: AppSize.s(12),
                  fontWeight: FontWeight.w600,
                  color: _levelColor,
                ),
              ),
            ),
            AppSize.gapH(8),
            Text(
              interpretation!.description,
              style: TextStyle(
                fontSize: AppSize.s(12),
                color: AppColors.mutedForeground,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
