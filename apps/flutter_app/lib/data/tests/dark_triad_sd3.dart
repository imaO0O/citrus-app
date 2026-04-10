import '../../../models/psychological_test.dart';

/// Dark Triad (SD3) — Краткая тёмная триада
/// Лицензия: Public Domain
class DarkTriadSD3Test {
  static const testId = 'dark_triad_sd3';

  static const _options = [
    'Полностью не согласен',
    'Не согласен',
    'Ни то ни сё',
    'Согласен',
    'Полностью согласен',
  ];

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'Краткая тёмная триада (SD3)',
        description:
            'Опросник «Тёмная триада» измеряет три социально-негативных личностных черты: нарциссизм, психопатию и макиавеллизм. Каждая шкала оценивает выраженность соответствующей черты.',
        icon: 'dark_triad',
        category: 'personality',
        durationMinutes: 5,
        questions: const [
          TestQuestion(
            id: 1,
            text: 'Я люблю быть в центре внимания',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 2,
            text: 'Я мстителен',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 3,
            text: 'Я использую людей ради своей выгоды',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 4,
            text: 'Я ожидал бы великих вещей от себя и от окружающих',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 5,
            text: 'Люди говорят, что я импульсивен',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 6,
            text: 'Я стремлюсь к восхищению',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 7,
            text: 'Важно, чтобы люди делали то, что я хочу',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 8,
            text: 'Люди часто говорят, что я неосторожен',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 9,
            text: 'Я требую особого отношения',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 10,
            text: 'Я знаю, что я особенный',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 11,
            text: 'Люди видят во мне жёсткого человека',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 12,
            text: 'Я лгу, чтобы получить желаемое',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 13,
            text: 'У меня есть природный талант лидерства',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 14,
            text: 'Я действую не задумываясь',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 15,
            text: 'Я люблю манипулировать людьми',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 16,
            text: 'Я избегаю прямых ответов на вопросы',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 17,
            text: 'Я жду от жизни лучшего',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 18,
            text: 'Мне всё равно, что правильно, а что нет',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 19,
            text: 'Я люблю хвастаться',
            options: _options,
            scoring: {'narcissism': 4},
          ),
          TestQuestion(
            id: 20,
            text: 'Я предпочитаю не раскрывать свои истинные намерения',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 21,
            text: 'Мне нравится быть жёстким',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 22,
            text: 'Я использую лесть, чтобы получить желаемое',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 23,
            text: 'Я рискую',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 24,
            text: 'Мне нравится льстить людям',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 25,
            text: 'Я манипулирую другими для достижения своих целей',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
          TestQuestion(
            id: 26,
            text: 'Я избегаю опасных ситуаций',
            options: _options,
            scoring: {'psychopathy': 4},
          ),
          TestQuestion(
            id: 27,
            text: 'Я делаю всё, чтобы добиться своего',
            options: _options,
            scoring: {'machiavellianism': 4},
          ),
        ],
        scoringScales: {
          'narcissism': const ScoringScale(
            name: 'narcissism',
            label: 'Нарциссизм',
            description:
                'Склонность к грандиозности, потребности в восхищении и ощущению собственной исключительности.',
            minScore: 0,
            maxScore: 45,
            interpretations: [
              ScoreInterpretation(
                level: 'low',
                label: 'Низкий уровень',
                description:
                    'У вас умеренное отношение к себе без выраженной потребности в восхищении. Вы не склонны к грандиозности.',
                minScore: 9,
                maxScore: 19,
              ),
              ScoreInterpretation(
                level: 'medium',
                label: 'Средний уровень',
                description:
                    'У вас умеренные нарциссические черты, свойственные большинству людей. Вы цените себя, но не ставите себя выше других.',
                minScore: 20,
                maxScore: 31,
              ),
              ScoreInterpretation(
                level: 'high',
                label: 'Высокий уровень',
                description:
                    'У вас выражены нарциссические черты: потребность в восхищении, ощущение собственной исключительности и склонность к грандиозности.',
                minScore: 32,
                maxScore: 45,
              ),
            ],
          ),
          'psychopathy': const ScoringScale(
            name: 'psychopathy',
            label: 'Психопатия',
            description:
                'Склонность к импульсивности, безрассудству и недостатку эмпатии.',
            minScore: 0,
            maxScore: 45,
            interpretations: [
              ScoreInterpretation(
                level: 'low',
                label: 'Низкий уровень',
                description:
                    'У вас низкая склонность к импульсивному и безрассудному поведению. Вы склонны обдумывать свои действия.',
                minScore: 9,
                maxScore: 19,
              ),
              ScoreInterpretation(
                level: 'medium',
                label: 'Средний уровень',
                description:
                    'У вас умеренные черты, свойственные большинству людей. Иногда вы можете действовать импульсивно.',
                minScore: 20,
                maxScore: 31,
              ),
              ScoreInterpretation(
                level: 'high',
                label: 'Высокий уровень',
                description:
                    'У вас выражены черты, связанные с импульсивностью, безрассудством и недостатком эмпатии. Это может влиять на ваши отношения с окружающими.',
                minScore: 32,
                maxScore: 45,
              ),
            ],
          ),
          'machiavellianism': const ScoringScale(
            name: 'machiavellianism',
            label: 'Макиавеллизм',
            description:
                'Склонность к манипуляциям, цинизму и стратегическому использованию других людей.',
            minScore: 0,
            maxScore: 45,
            interpretations: [
              ScoreInterpretation(
                level: 'low',
                label: 'Низкий уровень',
                description:
                    'Вы не склонны к манипуляциям и циничному отношению к людям. Вы цените честность и прямоту.',
                minScore: 9,
                maxScore: 19,
              ),
              ScoreInterpretation(
                level: 'medium',
                label: 'Средний уровень',
                description:
                    'У вас умеренные макиавеллистические черты. Иногда вы можете использовать тактику влияния для достижения целей.',
                minScore: 20,
                maxScore: 31,
              ),
              ScoreInterpretation(
                level: 'high',
                label: 'Высокий уровень',
                description:
                    'У вас выражены черты, связанные с манипулятивностью, цинизмом и стратегическим использованием других людей.',
                minScore: 32,
                maxScore: 45,
              ),
            ],
          ),
        },
      );
}
