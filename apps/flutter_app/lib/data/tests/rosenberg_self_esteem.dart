import '../../../models/psychological_test.dart';

/// Rosenberg Self-Esteem Scale
/// Лицензия: Public Domain
class RosenbergSelfEsteemTest {
  static const testId = 'rosenberg_self_esteem';

  static const _options = [
    'Полностью не согласен',
    'Не согласен',
    'Согласен',
    'Полностью согласен',
  ];

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'Шкала самооценки Розенберга',
        description:
            'Шкала самооценки Розенберга — одна из наиболее широко используемых шкал для измерения глобальной самооценки. Тест оценивает общее позитивное или негативное отношение к себе.',
        icon: 'self_esteem',
        category: 'personality',
        durationMinutes: 3,
        questions: const [
          TestQuestion(
            id: 1,
            text: 'В целом я доволен собой',
            options: _options,
            scoring: {'self_esteem': 3},
          ),
          TestQuestion(
            id: 2,
            text: 'Порой мне кажется, что я вовсе не так хорош, как я думал',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
          TestQuestion(
            id: 3,
            text: 'У меня есть ряд хороших качеств',
            options: _options,
            scoring: {'self_esteem': 3},
          ),
          TestQuestion(
            id: 4,
            text: 'Я отношусь к себе достаточно положительно',
            options: _options,
            scoring: {'self_esteem': 3},
          ),
          TestQuestion(
            id: 5,
            text: 'Мне нечего собой гордиться',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
          TestQuestion(
            id: 6,
            text: 'Иногда я чувствую себя бесполезным',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
          TestQuestion(
            id: 7,
            text: 'Мне бы хотелось больше уважения к себе',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
          TestQuestion(
            id: 8,
            text: 'Иногда я чувствую свою никчёмность',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
          TestQuestion(
            id: 9,
            text: 'Я чувствую, что я хороший человек',
            options: _options,
            scoring: {'self_esteem': 3},
          ),
          TestQuestion(
            id: 10,
            text: 'Я часто чувствую бессилие',
            options: _options,
            scoring: {'self_esteem': 0},
          ),
        ],
        scoringScales: {
          'self_esteem': const ScoringScale(
            name: 'self_esteem',
            label: 'Самооценка',
            description:
                'Общий уровень самооценки — от низкой до высокой.',
            minScore: 0,
            maxScore: 30,
            interpretations: [
              ScoreInterpretation(
                level: 'low',
                label: 'Низкая самооценка',
                description:
                    'Вы склонны критически относиться к себе и часто сомневаетесь в своих способностях. Это может указывать на необходимость работы над повышением самоуважения.',
                minScore: 0,
                maxScore: 14,
              ),
              ScoreInterpretation(
                level: 'medium',
                label: 'Нормальная самооценка',
                description:
                    'У вас адекватное отношение к себе. Вы способны признавать свои недостатки, но при этом цените свои достоинства.',
                minScore: 15,
                maxScore: 24,
              ),
              ScoreInterpretation(
                level: 'high',
                label: 'Высокая самооценка',
                description:
                    'Вы высоко оцениваете себя и свои качества. Это говорит о здоровом самоуважении и уверенности в себе.',
                minScore: 25,
                maxScore: 30,
              ),
            ],
          ),
        },
      );
}
