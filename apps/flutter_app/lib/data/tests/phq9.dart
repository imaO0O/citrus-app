// PHQ-9 - Patient Health Questionnaire (скрининг депрессии)
// Лицензия: Public Domain
// Источник: https://patienthealthquestionnaire.org/

import '../../../models/psychological_test.dart';

class PHQ9 {
  static const testId = 'phq9';

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'PHQ-9: Скрининг депрессии',
        description:
            'Опросник для оценки выраженности депрессивных симптомов за последние 2 недели.',
        icon: '📉',
        category: 'clinical',
        durationMinutes: 3,
        questions: _questions,
        scoringScales: _scales,
      );

  static const List<TestQuestion> _questions = [
    TestQuestion(
      id: 1,
      text: 'Малый интерес или удовольствие от вещей',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 2,
      text: 'Подавленное настроение, депрессия, безнадёжность',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 3,
      text: 'Нарушение сна: трудно засыпать, прерывистый сон',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 4,
      text: 'Чувство усталости или недостаток энергии',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 5,
      text: 'Плохой аппетит или переедание',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 6,
      text: 'Чувство вины, никчёмности, беспомощности',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 7,
      text: 'Трудности с концентрацией внимания',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 8,
      text: 'Замедленность или беспокойство, заметные окружающим',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
    TestQuestion(
      id: 9,
      text: 'Мысли о смерти или самоповреждении',
      options: ['Никогда', 'Несколько дней', 'Более половины дней', 'Почти каждый день'],
      scoring: {'depression': 1},
    ),
  ];

  static const Map<String, ScoringScale> _scales = {
    'depression': ScoringScale(
      name: 'depression',
      label: 'Выраженность депрессии',
      description:
          'Суммарный балл от 0 до 27, где более высокие значения указывают на более выраженные депрессивные симптомы.',
      minScore: 0,
      maxScore: 27,
      interpretations: [
        ScoreInterpretation(
          level: 'minimal',
          label: 'Минимальная',
          description: 'Симптомы депрессии не выражены. Поддерживайте здоровый образ жизни.',
          minScore: 0,
          maxScore: 4,
        ),
        ScoreInterpretation(
          level: 'mild',
          label: 'Лёгкая',
          description: 'Незначительные симптомы. Рекомендуется наблюдение.',
          minScore: 5,
          maxScore: 9,
        ),
        ScoreInterpretation(
          level: 'moderate',
          label: 'Умеренная',
          description: 'Умеренные симптомы. Рекомендуется консультация специалиста.',
          minScore: 10,
          maxScore: 14,
        ),
        ScoreInterpretation(
          level: 'moderately_severe',
          label: 'Умеренно тяжёлая',
          description: 'Выраженные симптомы. Обратитесь к специалисту.',
          minScore: 15,
          maxScore: 19,
        ),
        ScoreInterpretation(
          level: 'severe',
          label: 'Тяжёлая',
          description:
              'Сильно выраженные симптомы. Настоятельно рекомендуется обратиться к специалисту.',
          minScore: 20,
          maxScore: 27,
        ),
      ],
    ),
  };
}
