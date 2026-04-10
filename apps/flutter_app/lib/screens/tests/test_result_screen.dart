import 'package:flutter/material.dart';
import '../../models/psychological_test.dart';

class TestResultScreen extends StatelessWidget {
  final PsychologicalTest test;
  final Map<String, int> scores;
  final Map<String, ScoreInterpretation?> interpretations;

  const TestResultScreen({
    super.key,
    required this.test,
    required this.scores,
    required this.interpretations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'Результаты',
          style: TextStyle(
            color: Color(0xFFEDE8E0),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEDE8E0)),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Center(
              child: Column(
                children: [
                  Text(
                    test.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    test.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEDE8E0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Завершено ${_formatDate(DateTime.now())}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5A5468),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Результаты по шкалам
            const Text(
              'Ваши результаты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEDE8E0),
              ),
            ),
            const SizedBox(height: 16),

            ...scores.entries.map((entry) {
              final scale = test.scoringScales[entry.key];
              final interpretation = interpretations[entry.key];
              if (scale == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ScaleResultCard(
                  scale: scale,
                  score: entry.value,
                  interpretation: interpretation,
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Дисклеймер
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8C42).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF8C42),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Этот тест носит информационный характер. Для профессиональной консультации обратитесь к специалисту.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8298),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.replay),
                    label: const Text('Пройти снова'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEDE8E0),
                      side: const BorderSide(color: Color(0xFF5A5468)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    icon: const Icon(Icons.list),
                    label: const Text('Все тесты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  const _ScaleResultCard({
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
        return const Color(0xFF8BC34A);
      case 'medium':
      case 'mild':
        return const Color(0xFFFFD93D);
      case 'moderate':
        return const Color(0xFFFF8C42);
      case 'high':
      case 'severe':
      case 'moderately_severe':
      case 'extremely_severe':
        return const Color(0xFFFF5B5B);
      default:
        return const Color(0xFF8A8298);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.05),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEDE8E0),
                  ),
                ),
              ),
              Text(
                '$score / ${scale.maxScore}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8298),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFF2A2A3E),
              valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),

          // Уровень
          if (interpretation != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _levelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                interpretation!.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _levelColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              interpretation!.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8298),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
