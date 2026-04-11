import '../../models/psychological_test.dart';
import '../../data/tests/tests.dart';

/// Сервис для подсчёта результатов психологических тестов
class TestScoringService {
  /// Подсчитать баллы по шкалам для данного теста
  static Map<String, int> calculateScores(
      String testId, Map<int, int> answers) {
    final test = TestRegistry.getTest(testId);
    if (test == null) return {};

    final scores = <String, int>{};

    // Инициализируем шкалы нулями
    for (final scale in test.scoringScales.keys) {
      scores[scale] = 0;
    }

    // Подсчитываем баллы
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final answerIndex = entry.value;

      final question = test.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw Exception('Question $questionId not found'),
      );

      // Для DISC: ответ = индекс варианта, который соответствует одной шкале
      if (testId == 'disc') {
        // DISC: варианты D, I, S, C -> индексы 0, 1, 2, 3
        final scales = ['dominance', 'influence', 'steadiness', 'conscientiousness'];
        if (answerIndex >= 0 && answerIndex < scales.length) {
          final scaleName = scales[answerIndex];
          scores[scaleName] = (scores[scaleName] ?? 0) + 1;
        }
      } else {
        // Для остальных тестов: answerIndex (0-4) -> score (1-5 или 0-3)
        for (final scaleEntry in question.scoring.entries) {
          final scaleName = scaleEntry.key;
          final baseScore = scaleEntry.value;

          // Если score отрицательный - это обратный вопрос
          final isReversed = baseScore < 0;

          // answerIndex: 0=очень неточно, 1=неточно, 2=ни то ни сё, 3=точно, 4=очень точно
          // Для обычных: score = answerIndex + 1
          // Для обратных: score = (maxAnswer - answerIndex) + 1
          int score;
          if (isReversed) {
            score = (4 - answerIndex) + 1;
          } else {
            score = answerIndex + 1;
          }

          // Для тестов с 4 вариантами (PHQ-9, GAD-7, DASS-21, Rosenberg)
          // answerIndex: 0-3 -> score: 0-3
          if (['phq9', 'gad7', 'dass21', 'rosenberg_self_esteem'].contains(testId)) {
            score = answerIndex;
            if (isReversed) {
              score = 3 - answerIndex;
            }
          }

          scores[scaleName] = (scores[scaleName] ?? 0) + score;
        }
      }
    }

    // Для DASS-21 умножаем на 2
    if (testId == 'dass21') {
      scores.updateAll((key, value) => value * 2);
    }

    return scores;
  }

  /// Получить интерпретацию для шкалы
  static ScoreInterpretation? getInterpretation(
      String testId, String scaleName, int score) {
    final test = TestRegistry.getTest(testId);
    if (test == null) return null;

    final scale = test.scoringScales[scaleName];
    if (scale == null) return null;

    for (final interp in scale.interpretations) {
      if (score >= interp.minScore && score <= interp.maxScore) {
        return interp;
      }
    }

    return null;
  }

  /// Получить все интерпретации для результатов
  static Map<String, ScoreInterpretation?> getAllInterpretations(
      String testId, Map<String, int> scores) {
    final result = <String, ScoreInterpretation?>{};

    for (final entry in scores.entries) {
      result[entry.key] = getInterpretation(testId, entry.key, entry.value);
    }

    return result;
  }
}
