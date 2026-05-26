import '../../../models/psychological_test.dart';

/// DASS-21 (Depression Anxiety Stress Scales - 21 item)
/// Шкала депрессии, тревожности и стресса
/// Лицензия: Public Domain
class Dass21Test {
  static const testId = 'dass21';

  static const _options = [
    'Никогда',
    'Иногда',
    'Часто',
    'Почти всегда',
  ];

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'DASS-21',
        description:
            'Шкала депрессии, тревожности и стресса (21 вопрос). '
            'Оценивает три параметра за последнюю неделю.',
        icon: '📊',
        category: 'clinical',
        durationMinutes: 5,
        questions: const [
          // Stress: 1, 6, 8, 11, 12, 14, 18
          TestQuestion(
            id: 1,
            text: 'Мне было трудно успокоиться',
            options: _options,
            scoring: {'stress': 1},
          ),
          // Anxiety: 2, 4, 7, 9, 15, 19, 20
          TestQuestion(
            id: 2,
            text: 'Я ощущал сухость во рту',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          // Depression: 3, 5, 10, 13, 16, 17, 21
          TestQuestion(
            id: 3,
            text: 'Мне казалось, что в жизни нет ничего приятного',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 4,
            text: 'У меня было затруднённое дыхание',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 5,
            text: 'Мне было трудно проявить инициативу',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 6,
            text: 'Я реагировал слишком остро на ситуации',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 7,
            text: 'Я чувствовал дрожь',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 8,
            text: 'Я чувствовал, что трачу много нервной энергии',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 9,
            text: 'Меня беспокоили ситуации, в которых я мог бы запаниковать',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 10,
            text: 'Мне казалось, что мне не на что надеяться',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 11,
            text: 'Я чувствовал напряжение',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 12,
            text: 'Мне было трудно расслабиться',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 13,
            text: 'Я чувствовал грусть и подавленность',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 14,
            text: 'Я не мог терпеть ничего, что мешало мне продолжать начатое',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 15,
            text: 'Я чувствовал, что близок к панике',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 16,
            text: 'Мне было трудно воодушевиться',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 17,
            text: 'Я чувствовал, что ничего не стою',
            options: _options,
            scoring: {'depression': 1},
          ),
          TestQuestion(
            id: 18,
            text: 'Я был очень восприимчив',
            options: _options,
            scoring: {'stress': 1},
          ),
          TestQuestion(
            id: 19,
            text:
                'Я чувствовал учащённое сердцебиение без физической нагрузки',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 20,
            text: 'Я ощущал страх без причины',
            options: _options,
            scoring: {'anxiety': 1},
          ),
          TestQuestion(
            id: 21,
            text: 'Я чувствовал, что жизнь не имеет смысла',
            options: _options,
            scoring: {'depression': 1},
          ),
        ],
        scoringScales: const {
          'depression': ScoringScale(
            name: 'depression',
            label: 'Депрессия',
            description: 'Уровень депрессивных симптомов',
            minScore: 0,
            maxScore: 42,
            interpretations: [
              ScoreInterpretation(
                level: 'normal',
                label: 'Норма',
                description: 'Нормальный уровень',
                minScore: 0,
                maxScore: 9,
              ),
              ScoreInterpretation(
                level: 'mild',
                label: 'Лёгкая',
                description: 'Лёгкая депрессия',
                minScore: 10,
                maxScore: 13,
              ),
              ScoreInterpretation(
                level: 'moderate',
                label: 'Умеренная',
                description: 'Умеренная депрессия',
                minScore: 14,
                maxScore: 20,
              ),
              ScoreInterpretation(
                level: 'severe',
                label: 'Тяжёлая',
                description: 'Тяжёлая депрессия',
                minScore: 21,
                maxScore: 27,
              ),
              ScoreInterpretation(
                level: 'extremely_severe',
                label: 'Крайне тяжёлая',
                description: 'Крайне тяжёлая депрессия',
                minScore: 28,
                maxScore: 42,
              ),
            ],
          ),
          'anxiety': ScoringScale(
            name: 'anxiety',
            label: 'Тревожность',
            description: 'Уровень тревожности',
            minScore: 0,
            maxScore: 42,
            interpretations: [
              ScoreInterpretation(
                level: 'normal',
                label: 'Норма',
                description: 'Нормальный уровень',
                minScore: 0,
                maxScore: 7,
              ),
              ScoreInterpretation(
                level: 'mild',
                label: 'Лёгкая',
                description: 'Лёгкая тревожность',
                minScore: 8,
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
                maxScore: 19,
              ),
              ScoreInterpretation(
                level: 'extremely_severe',
                label: 'Крайне тяжёлая',
                description: 'Крайне тяжёлая тревожность',
                minScore: 20,
                maxScore: 42,
              ),
            ],
          ),
          'stress': ScoringScale(
            name: 'stress',
            label: 'Стресс',
            description: 'Уровень стресса',
            minScore: 0,
            maxScore: 42,
            interpretations: [
              ScoreInterpretation(
                level: 'normal',
                label: 'Норма',
                description: 'Нормальный уровень',
                minScore: 0,
                maxScore: 14,
              ),
              ScoreInterpretation(
                level: 'mild',
                label: 'Лёгкий',
                description: 'Лёгкий стресс',
                minScore: 15,
                maxScore: 18,
              ),
              ScoreInterpretation(
                level: 'moderate',
                label: 'Умеренный',
                description: 'Умеренный стресс',
                minScore: 19,
                maxScore: 25,
              ),
              ScoreInterpretation(
                level: 'severe',
                label: 'Тяжёлый',
                description: 'Тяжёлый стресс',
                minScore: 26,
                maxScore: 33,
              ),
              ScoreInterpretation(
                level: 'extremely_severe',
                label: 'Крайне тяжёлый',
                description: 'Крайне тяжёлый стресс',
                minScore: 34,
                maxScore: 42,
              ),
            ],
          ),
        },
      );
}
