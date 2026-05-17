// Big Five (IPIP-50) - 50 вопросов, 5 шкал
// Лицензия: Public Domain
// Источник: https://ipip.ori.org/

import '../../../models/psychological_test.dart';

class BigFiveIPIP50 {
  static const testId = 'big_five_ipip_50';

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'Большая пятёрка (IPIP-50)',
        description:
            'Опросник измеряет 5 основных черт личности: открытость опыту, добросовестность, экстраверсию, доброжелательность и нейротизм.',
        icon: '🧠',
        category: 'personality',
        durationMinutes: 10,
        questions: _questions,
        scoringScales: _scales,
      );

  static const List<TestQuestion> _questions = [
    // === ОТКРЫТОСТЬ ОПЫТУ (Openness) ===
    TestQuestion(
      id: 1,
      text: 'У меня богатое воображение',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 2,
      text: 'Мне не интересно размышлять о природе вселенной',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': -5},
    ),
    TestQuestion(
      id: 3,
      text: 'Я воспринимаю вещи такими, какие они есть',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': -5},
    ),
    TestQuestion(
      id: 4,
      text: 'Я люблю размышлять, играть с идеями',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 5,
      text: 'У меня живое воображение',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 6,
      text: 'Мне не нравятся абстрактные идеи',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': -5},
    ),
    TestQuestion(
      id: 7,
      text: 'Мне нравится искусство',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 8,
      text: 'Мне неинтересно, как устроен мир',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': -5},
    ),
    TestQuestion(
      id: 9,
      text: 'Мне нравится поэзия',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 10,
      text: 'Я не люблю философствовать',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'openness': -5},
    ),

    // === ДОБРОСОВЕСТНОСТЬ (Conscientiousness) ===
    TestQuestion(
      id: 11,
      text: 'У меня всегда порядок в вещах',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 12,
      text: 'Я часто забываю положить вещи на место',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': -5},
    ),
    TestQuestion(
      id: 13,
      text: 'Я люблю порядок',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 14,
      text: 'Мне не нравятся графики и расписания',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': -5},
    ),
    TestQuestion(
      id: 15,
      text: 'Я всегда готов',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 16,
      text: 'Я часто трачу вещи не на своё место',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': -5},
    ),
    TestQuestion(
      id: 17,
      text: 'Я следую расписанию',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 18,
      text: 'Мне трудно придерживаться расписания',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': -5},
    ),
    TestQuestion(
      id: 19,
      text: 'Я уделяю внимание деталям',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 20,
      text: 'Я делаю работу небрежно',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'conscientiousness': -5},
    ),

    // === ЭКСТРАВЕРСИЯ (Extraversion) ===
    TestQuestion(
      id: 21,
      text: 'Я мало говорю',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': -5},
    ),
    TestQuestion(
      id: 22,
      text: 'Я люблю быть в центре внимания',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 23,
      text: 'Мне комфортно в тишине',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': -5},
    ),
    TestQuestion(
      id: 24,
      text: 'Я завязываю разговор',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 25,
      text: 'У меня не так много друзей',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': -5},
    ),
    TestQuestion(
      id: 26,
      text: 'Я чувствую себя комфортно среди людей',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 27,
      text: 'Я предпочитаю работать один',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': -5},
    ),
    TestQuestion(
      id: 28,
      text: 'Я полон энергии',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 29,
      text: 'Я жду, пока другие начнут разговор',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': -5},
    ),
    TestQuestion(
      id: 30,
      text: 'Я беру на себя ответственность',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'extraversion': 5},
    ),

    // === ДОБРОЖЕЛАТЕЛЬНОСТЬ (Agreeableness) ===
    TestQuestion(
      id: 31,
      text: 'Я не интересуюсь проблемами других людей',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': -5},
    ),
    TestQuestion(
      id: 32,
      text: 'Я сочувствую чужим чувствам',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 33,
      text: 'Мне всё равно, что чувствуют другие',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': -5},
    ),
    TestQuestion(
      id: 34,
      text: 'Я люблю помогать другим',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 35,
      text: 'Я могу быть равнодушным',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': -5},
    ),
    TestQuestion(
      id: 36,
      text: 'Меня трогают чужие проблемы',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 37,
      text: 'Я не доверяю людям',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': -5},
    ),
    TestQuestion(
      id: 38,
      text: 'Я верю людям',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 39,
      text: 'Я оскорбляю людей',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': -5},
    ),
    TestQuestion(
      id: 40,
      text: 'Я уважаю других',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'agreeableness': 5},
    ),

    // === НЕЙРОТИЗМ (Neuroticism) ===
    TestQuestion(
      id: 41,
      text: 'Я часто расстраиваюсь',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 42,
      text: 'Я легко расслабляюсь',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': -5},
    ),
    TestQuestion(
      id: 43,
      text: 'Я часто бываю в унынии',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 44,
      text: 'Я редко чувствую себя одиноким',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': -5},
    ),
    TestQuestion(
      id: 45,
      text: 'Я часто бываю раздражён',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 46,
      text: 'Я эмоционально устойчив',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': -5},
    ),
    TestQuestion(
      id: 47,
      text: 'Я часто нервничаю',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 48,
      text: 'Я редко чувствую себя подавленным',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': -5},
    ),
    TestQuestion(
      id: 49,
      text: 'Я беспокоюсь о вещах',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 50,
      text: 'Меня легко расстроить',
      options: [
        'Очень неточно',
        'Неточно',
        'Ни то ни сё',
        'Точно',
        'Очень точно',
      ],
      scoring: {'neuroticism': 5},
    ),
  ];

  static const Map<String, ScoringScale> _scales = {
    'openness': ScoringScale(
      name: 'openness',
      label: 'Открытость опыту',
      description:
          'Отражает степень любопытства, креативности и предпочтения к новому.',
      minScore: 10,
      maxScore: 50,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкая',
          description:
              'Вы предпочитаете традиции, практичность и привычные решения.',
          minScore: 10,
          maxScore: 24,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средняя',
          description:
              'Вы умеете балансировать между традициями и новшествами.',
          minScore: 25,
          maxScore: 35,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокая',
          description:
              'Вы любознательны, креативны и открыты новому опыту.',
          minScore: 36,
          maxScore: 50,
        ),
      ],
    ),
    'conscientiousness': ScoringScale(
      name: 'conscientiousness',
      label: 'Добросовестность',
      description:
          'Отражает организованность, ответственность и стремление к целям.',
      minScore: 10,
      maxScore: 50,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкая',
          description: 'Вы гибки и спонтанны, но можете быть неорганизованны.',
          minScore: 10,
          maxScore: 24,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средняя',
          description:
              'Вы умеете сочетать организованность с гибкостью.',
          minScore: 25,
          maxScore: 35,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокая',
          description:
              'Вы дисциплинированны, организованны и стремитесь к завершённости.',
          minScore: 36,
          maxScore: 50,
        ),
      ],
    ),
    'extraversion': ScoringScale(
      name: 'extraversion',
      label: 'Экстраверсия',
      description:
          'Отражает степень общительности, энергичности и стремления к стимуляции.',
      minScore: 10,
      maxScore: 50,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Интроверсия',
          description:
              'Вы предпочитаете тишину, одиночество и глубокую концентрацию.',
          minScore: 10,
          maxScore: 24,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Амбиверсия',
          description:
              'Вы можете быть общительны или сдержанны в зависимости от ситуации.',
          minScore: 25,
          maxScore: 35,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Экстраверсия',
          description:
              'Вы энергичны, общительны и заряжаетесь от общения.',
          minScore: 36,
          maxScore: 50,
        ),
      ],
    ),
    'agreeableness': ScoringScale(
      name: 'agreeableness',
      label: 'Доброжелательность',
      description:
          'Отражает степень доверия, доброты и склонности к сотрудничеству.',
      minScore: 10,
      maxScore: 50,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкая',
          description:
              'Вы скептичны, конкурентны и ставите свои интересы выше.',
          minScore: 10,
          maxScore: 24,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средняя',
          description:
              'Вы умеете балансировать между своими и чужими интересами.',
          minScore: 25,
          maxScore: 35,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокая',
          description:
              'Вы доверчивы, добры и стремитесь к гармонии с окружающими.',
          minScore: 36,
          maxScore: 50,
        ),
      ],
    ),
    'neuroticism': ScoringScale(
      name: 'neuroticism',
      label: 'Нейротизм',
      description:
          'Отражает склонность к негативным эмоциям: тревоге, депрессии, гневу.',
      minScore: 10,
      maxScore: 50,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Эмоциональная стабильность',
          description:
              'Вы спокойны, уверены и редко расстраиваетесь.',
          minScore: 10,
          maxScore: 24,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средняя',
          description:
              'Вы иногда переживаете, но в целом справляетесь со стрессом.',
          minScore: 25,
          maxScore: 35,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокая чувствительность',
          description:
              'Вы склонны к сильным переживаниям и часто расстраиваетесь.',
          minScore: 36,
          maxScore: 50,
        ),
      ],
    ),
  };
}
