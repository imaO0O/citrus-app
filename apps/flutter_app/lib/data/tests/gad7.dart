import '../../../models/psychological_test.dart';

/// GAD-7 (Generalized Anxiety Disorder 7-item)
/// Скрининг генерализованного тревожного расстройства
/// Лицензия: Public Domain
class Gad7Test {
  static const testId = 'gad7';

  static const _options = [
    'Никогда',
    'Несколько дней',
    'Более половины дней',
    'Почти каждый день',
  ];

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'GAD-7',
        description:
            'Шкала генерализованного тревожного расстройства (7 вопросов). '
            'Оценивает уровень тревожности за последние 2 недели.',
        icon: '🧠',
        category: 'clinical',
        durationMinutes: 3,
        questions: const [
          TestQuestion(
            id: 1,
            text: 'Нервозность, тревога, напряжённость',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 2,
            text: 'Невозможность прекратить или контролировать беспокойство',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 3,
            text: 'Слишком сильное беспокойство о разных вещах',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 4,
            text: 'Трудности с расслаблением',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 5,
            text: 'Беспокойство, из-за которого трудно сидеть спокойно',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 6,
            text: 'Легко расстраиваюсь или раздражаюсь',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 7,
            text: 'Ощущение страха, будто что-то ужасное может случиться',
            options: _options,
            scoring: {'anxiety': 1},
          ),
        ],
        scoringScales: const {
          'anxiety': ScoringScale(
            name: 'anxiety',
            label: 'Тревожность',
            description: 'Уровень генерализованной тревожности',
            minScore: 0,
            maxScore: 21,
            interpretations: [
              ScoreInterpretation(
                level: 'minimal',
                label: 'Минимальная',
                description: 'Минимальная тревожность',
                minScore: 0,
                maxScore: 4,
              ),
              ScoreInterpretation(
                level: 'mild',
                label: 'Лёгкая',
                description: 'Лёгкая тревожность',
                minScore: 5,
                maxScore: 9,
              ),
              ScoreInterpretation(
                level: 'moderate',
                label: 'Умеренная',
                description: 'Умеренная тревожность',
                minScore: 10,
                maxScore: 14,
              ),
              ScoreInterpretation(
                level: 'severe',
                label: 'Тяжёлая',
                description: 'Тяжёлая тревожность',
                minScore: 15,
                maxScore: 21,
              ),
            ],
          ),
        },
      );
}
