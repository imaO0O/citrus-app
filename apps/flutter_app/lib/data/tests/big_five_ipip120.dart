/// Big Five (IPIP-120) — расширенный тест личности
///
/// Лицензия: Public Domain
/// Источник: https://ipip.ori.org/
///
/// 120 вопросов, 5 шкал, по 4 аспекта на шкалу (по 6 вопросов на аспект).
/// Варианты ответов: 5-балльная шкала Лайкерта.

import '../../../models/psychological_test.dart';

class BigFiveIPIP120 {
  static const testId = 'big_five_ipip120';

  static const _options = [
    'Очень неточно',
    'Неточно',
    'Ни то ни сё',
    'Точно',
    'Очень точно',
  ];

  // ---------------------------------------------------------------------------
  // Questions 1-120
  // ---------------------------------------------------------------------------
  static const List<TestQuestion> _questions = [
    // =========================================================================
    // 1. ОТКРЫТОСТЬ — Воображение (Imagination): Q1–Q6
    // =========================================================================
    TestQuestion(
      id: 1,
      text:
          'У меня богатое воображение.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 2,
      text:
          'Мне трудно понимать абстрактные идеи.',
      options: _options,
      scoring: {'openness': 2},
    ),
    TestQuestion(
      id: 3,
      text:
          'Я часто мечтаю наяву.',
      options: _options,
      scoring: {'openness': 4},
    ),
    TestQuestion(
      id: 4,
      text:
          'Мне не интересно размышлять о природе вещей или устройстве вселенной.',
      options: _options,
      scoring: {'openness': 1},
    ),
    TestQuestion(
      id: 5,
      text:
          'Я предпочитаю работу, требующую творческого подхода.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 6,
      text:
          'Я избегаю философских дискуссий.',
      options: _options,
      scoring: {'openness': 2},
    ),

    // =========================================================================
    // ОТКРЫТОСТЬ — Художественные интересы (Artistic interests): Q7–Q12
    // =========================================================================
    TestQuestion(
      id: 7,
      text:
          'У меня хорошая фантазия.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 8,
      text:
          'Я не люблю искусство.',
      options: _options,
      scoring: {'openness': 1},
    ),
    TestQuestion(
      id: 9,
      text:
          'Мне нравятся красивые вещи.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 10,
      text:
          'Я не ценю поэзию.',
      options: _options,
      scoring: {'openness': 1},
    ),
    TestQuestion(
      id: 11,
      text:
          'Меня вдохновляет музыка.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 12,
      text:
          'Я не интересуюсь выставками и музеями.',
      options: _options,
      scoring: {'openness': 2},
    ),

    // =========================================================================
    // ОТКРЫТОСТЬ — Эмоциональность (Emotionality): Q13–Q18
    // =========================================================================
    TestQuestion(
      id: 13,
      text:
          'Я легко воспринимаю новые идеи.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 14,
      text:
          'Я не впечатлителен.',
      options: _options,
      scoring: {'openness': 1},
    ),
    TestQuestion(
      id: 15,
      text:
          'Я глубоко переживаю эмоции.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 16,
      text:
          'Я редко замечаю свои чувства.',
      options: _options,
      scoring: {'openness': 2},
    ),
    TestQuestion(
      id: 17,
      text:
          'Меня трогают истории о людях.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 18,
      text:
          'Я не склонен к сильным переживаниям.',
      options: _options,
      scoring: {'openness': 1},
    ),

    // =========================================================================
    // ОТКРЫТОСТЬ — Приключения (Adventurousness): Q19–Q24
    // =========================================================================
    TestQuestion(
      id: 19,
      text:
          'Я люблю пробовать новое.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 20,
      text:
          'Я предпочитаю привычный распорядок.',
      options: _options,
      scoring: {'openness': 2},
    ),
    TestQuestion(
      id: 21,
      text:
          'Мне нравятся путешествия в незнакомые места.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 22,
      text:
          'Я избегаю перемен.',
      options: _options,
      scoring: {'openness': 1},
    ),
    TestQuestion(
      id: 23,
      text:
          'Я с радостью берусь за незнакомые дела.',
      options: _options,
      scoring: {'openness': 5},
    ),
    TestQuestion(
      id: 24,
      text:
          'Я предпочитаю делать всё по привычке.',
      options: _options,
      scoring: {'openness': 2},
    ),

    // =========================================================================
    // 2. ДОБРОСОВЕСТНОСТЬ — Самоэффективность (Self-efficacy): Q25–Q30
    // =========================================================================
    TestQuestion(
      id: 25,
      text:
          'Я всегда готов.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 26,
      text:
          'Я часто забываю положить вещи на место.',
      options: _options,
      scoring: {'conscientiousness': 2},
    ),
    TestQuestion(
      id: 27,
      text:
          'Я выполняю задачи успешно.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 28,
      text:
          'Я трачу время на пустяки.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),
    TestQuestion(
      id: 29,
      text:
          'Я добиваюсь поставленных целей.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 30,
      text:
          'Мне трудно приступить к трудным задачам.',
      options: _options,
      scoring: {'conscientiousness': 2},
    ),

    // =========================================================================
    // ДОБРОСОВЕСТНОСТЬ — Порядок (Orderliness): Q31–Q36
    // =========================================================================
    TestQuestion(
      id: 31,
      text:
          'Я люблю порядок.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 32,
      text:
          'Моя комната часто в беспорядке.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),
    TestQuestion(
      id: 33,
      text:
          'Я всё раскладываю по местам.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 34,
      text:
          'Я не забочусь о своих вещах.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),
    TestQuestion(
      id: 35,
      text:
          'Я составляю списки дел.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 36,
      text:
          'Я живу в хаосе.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),

    // =========================================================================
    // ДОБРОСОВЕСТНОСТЬ — Должностность (Dutifulness): Q37–Q42
    // =========================================================================
    TestQuestion(
      id: 37,
      text:
          'Я соблюдаю правила.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 38,
      text:
          'Я пытаюсь обойти правила.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),
    TestQuestion(
      id: 39,
      text:
          'Я держу слово.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 40,
      text:
          'Я часто опаздываю.',
      options: _options,
      scoring: {'conscientiousness': 2},
    ),
    TestQuestion(
      id: 41,
      text:
          'Я выполняю свои обязанности.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 42,
      text:
          'Я уклоняюсь от обязанностей.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),

    // =========================================================================
    // ДОБРОСОВЕСТНОСТЬ — Стремление к достижению (Achievement-striving): Q43–Q48
    // =========================================================================
    TestQuestion(
      id: 43,
      text:
          'Я работаю усердно.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 44,
      text:
          'Я доволен средними результатами.',
      options: _options,
      scoring: {'conscientiousness': 2},
    ),
    TestQuestion(
      id: 45,
      text:
          'Я стремлюсь к совершенству.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 46,
      text:
          'Я делаю только необходимое.',
      options: _options,
      scoring: {'conscientiousness': 2},
    ),
    TestQuestion(
      id: 47,
      text:
          'Я ставлю перед собой высокие цели.',
      options: _options,
      scoring: {'conscientiousness': 5},
    ),
    TestQuestion(
      id: 48,
      text:
          'Я не стремлюсь быть лучшим.',
      options: _options,
      scoring: {'conscientiousness': 1},
    ),

    // =========================================================================
    // 3. ЭКСТРАВЕРСИЯ — Дружелюбие (Friendliness): Q49–Q54
    // =========================================================================
    TestQuestion(
      id: 49,
      text:
          'Я легко завожу друзей.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 50,
      text:
          'Я держу дистанцию с незнакомцами.',
      options: _options,
      scoring: {'extraversion': 2},
    ),
    TestQuestion(
      id: 51,
      text:
          'Я люблю общаться с людьми.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 52,
      text:
          'Я избегаю новых знакомств.',
      options: _options,
      scoring: {'extraversion': 1},
    ),
    TestQuestion(
      id: 53,
      text:
          'Я первым начинаю разговор.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 54,
      text:
          'Мне трудно подходить к людям.',
      options: _options,
      scoring: {'extraversion': 1},
    ),

    // =========================================================================
    // ЭКСТРАВЕРСИЯ — Общительность (Gregariousness): Q55–Q60
    // =========================================================================
    TestQuestion(
      id: 55,
      text:
          'Я люблю большие компании.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 56,
      text:
          'Я предпочитаю одиночество.',
      options: _options,
      scoring: {'extraversion': 1},
    ),
    TestQuestion(
      id: 57,
      text:
          'Мне весело в шумной компании.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 58,
      text:
          'Я стараюсь избегать скопления людей.',
      options: _options,
      scoring: {'extraversion': 1},
    ),
    TestQuestion(
      id: 59,
      text:
          'Я люблю быть среди людей.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 60,
      text:
          'Мне некомфортно в толпе.',
      options: _options,
      scoring: {'extraversion': 2},
    ),

    // =========================================================================
    // ЭКСТРАВЕРСИЯ — Напористость (Assertiveness): Q61–Q66
    // =========================================================================
    TestQuestion(
      id: 61,
      text:
          'Я беру на себя руководство.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 62,
      text:
          'Я жду, пока другие сделают первый шаг.',
      options: _options,
      scoring: {'extraversion': 2},
    ),
    TestQuestion(
      id: 63,
      text:
          'Я высказываю своё мнение.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 64,
      text:
          'Я избегаю брать ответственность.',
      options: _options,
      scoring: {'extraversion': 1},
    ),
    TestQuestion(
      id: 65,
      text:
          'Я умею убеждать людей.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 66,
      text:
          'Мне трудно настаивать на своём.',
      options: _options,
      scoring: {'extraversion': 1},
    ),

    // =========================================================================
    // ЭКСТРАВЕРСИЯ — Уровень активности (Activity level): Q67–Q72
    // =========================================================================
    TestQuestion(
      id: 67,
      text:
          'Я всегда в движении.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 68,
      text:
          'Мне нравится неспешный образ жизни.',
      options: _options,
      scoring: {'extraversion': 2},
    ),
    TestQuestion(
      id: 69,
      text:
          'Я делаю всё быстро.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 70,
      text:
          'Я не тороплюсь.',
      options: _options,
      scoring: {'extraversion': 2},
    ),
    TestQuestion(
      id: 71,
      text:
          'У меня много энергии.',
      options: _options,
      scoring: {'extraversion': 5},
    ),
    TestQuestion(
      id: 72,
      text:
          'Я предпочитаю отдыхать, чем действовать.',
      options: _options,
      scoring: {'extraversion': 2},
    ),

    // =========================================================================
    // 4. ДОБРОЖЕЛАТЕЛЬНОСТЬ — Доверие (Trust): Q73–Q78
    // =========================================================================
    TestQuestion(
      id: 73,
      text:
          'Я верю людям.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 74,
      text:
          'Я подозреваю худшее о людях.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 75,
      text:
          'Я считаю людей честными.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 76,
      text:
          'Я осторожен с незнакомцами.',
      options: _options,
      scoring: {'agreeableness': 2},
    ),
    TestQuestion(
      id: 77,
      text:
          'Я доверяю окружающим.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 78,
      text:
          'Я ожидаю от людей подвоха.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),

    // =========================================================================
    // ДОБРОЖЕЛАТЕЛЬНОСТЬ — Мораль (Morality): Q79–Q84
    // =========================================================================
    TestQuestion(
      id: 79,
      text:
          'Я говорю правду.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 80,
      text:
          'Я могу схитрить ради выгоды.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 81,
      text:
          'Я честен с другими.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 82,
      text:
          'Я иногда обманываю, чтобы избежать проблем.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 83,
      text:
          'Я поступаю по совести.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 84,
      text:
          'Я использую людей в своих интересах.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),

    // =========================================================================
    // ДОБРОЖЕЛАТЕЛЬНОСТЬ — Альтруизм (Altruism): Q85–Q90
    // =========================================================================
    TestQuestion(
      id: 85,
      text:
          'Я помогаю другим.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 86,
      text:
          'Меня не волнуют проблемы других.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 87,
      text:
          'Я жертвую своим временем ради других.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 88,
      text:
          'Я не обращаю внимания на тех, кому плохо.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 89,
      text:
          'Я стараюсь помочь каждому.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 90,
      text:
          'Я слишком занят, чтобы помогать другим.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),

    // =========================================================================
    // ДОБРОЖЕЛАТЕЛЬНОСТЬ — Согласие (Cooperation): Q91–Q96
    // =========================================================================
    TestQuestion(
      id: 91,
      text:
          'Я легко иду на компромисс.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 92,
      text:
          'Я люблю спорить.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 93,
      text:
          'Я избегаю конфликтов.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 94,
      text:
          'Я оскорбляю людей, когда злюсь.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),
    TestQuestion(
      id: 95,
      text:
          'Я уступаю ради мира.',
      options: _options,
      scoring: {'agreeableness': 5},
    ),
    TestQuestion(
      id: 96,
      text:
          'Я мстителен.',
      options: _options,
      scoring: {'agreeableness': 1},
    ),

    // =========================================================================
    // 5. НЕЙРОТИЗМ — Тревожность (Anxiety): Q97–Q102
    // =========================================================================
    TestQuestion(
      id: 97,
      text:
          'Я легко впадаю в панику.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 98,
      text:
          'Я редко чувствую тревогу.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),
    TestQuestion(
      id: 99,
      text:
          'Я часто беспокоюсь.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 100,
      text:
          'Меня трудно вывести из себя.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),
    TestQuestion(
      id: 101,
      text:
          'Я часто чувствую страх.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 102,
      text:
          'Я спокоен под давлением.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),

    // =========================================================================
    // НЕЙРОТИЗМ — Гнев (Anger): Q103–Q108
    // =========================================================================
    TestQuestion(
      id: 103,
      text:
          'Я быстро выхожу из себя.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 104,
      text:
          'Меня трудно разозлить.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),
    TestQuestion(
      id: 105,
      text:
          'Я часто раздражаюсь.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 106,
      text:
          'Я редко злюсь.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),
    TestQuestion(
      id: 107,
      text:
          'Я вспыльчив.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 108,
      text:
          'Я сохраняю хладнокровие.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),

    // =========================================================================
    // НЕЙРОТИЗМ — Депрессия (Depression): Q109–Q114
    // =========================================================================
    TestQuestion(
      id: 109,
      text:
          'Я часто чувствую себя одиноким.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 110,
      text:
          'Я редко грущу.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),
    TestQuestion(
      id: 111,
      text:
          'Мне бывает трудно собраться с духом.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 112,
      text:
          'Я доволен жизнью.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),
    TestQuestion(
      id: 113,
      text:
          'Я часто чувствую безнадёжность.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 114,
      text:
          'Я оптимистично смотрю в будущее.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),

    // =========================================================================
    // НЕЙРОТИЗМ — Самосознание (Self-consciousness): Q115–Q120
    // =========================================================================
    TestQuestion(
      id: 115,
      text:
          'Меня легко смутить.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 116,
      text:
          'Я чувствую себя уверенно.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),
    TestQuestion(
      id: 117,
      text:
          'Мне неудобно, когда на меня обращают внимание.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 118,
      text:
          'Я не стесняюсь.',
      options: _options,
      scoring: {'neuroticism': 1},
    ),
    TestQuestion(
      id: 119,
      text:
          'Я чувствую неловкость в обществе.',
      options: _options,
      scoring: {'neuroticism': 5},
    ),
    TestQuestion(
      id: 120,
      text:
          'Я легко общаюсь с незнакомцами.',
      options: _options,
      scoring: {'neuroticism': 2},
    ),
  ];

  // ---------------------------------------------------------------------------
  // Scoring scales
  // ---------------------------------------------------------------------------
  static const Map<String, ScoringScale> _scoringScales = {
    'openness': ScoringScale(
      name: 'openness',
      label: 'Открытость опыту',
      description:
          'Отражает стремление к познанию, творчеству, восприимчивость '
          'к новому и готовность к интеллектуальному поиску.',
      minScore: 24,
      maxScore: 120,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы предпочитаете проверенные методы и традиционный подход. '
              'Вам комфортны привычные задачи и знакомое окружение.',
          minScore: 24,
          maxScore: 56,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы сочетаете интерес к новому с разумной осторожностью. '
              'Открыты к переменам, но цените стабильность.',
          minScore: 57,
          maxScore: 88,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы творческий, любознательный человек с богатым воображением. '
              'Вас вдохновляют новые идеи и необычный опыт.',
          minScore: 89,
          maxScore: 120,
        ),
      ],
    ),
    'conscientiousness': ScoringScale(
      name: 'conscientiousness',
      label: 'Добросовестность',
      description:
          'Отражает организованность, надёжность, настойчивость '
          'и ориентированность на достижение целей.',
      minScore: 24,
      maxScore: 120,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы склонны к спонтанности и гибкости. Вам может быть '
              'сложно следовать жёстким планам и правилам.',
          minScore: 24,
          maxScore: 56,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы сочетаете организованность с достаточной гибкостью. '
              'Планируете важное, но допускаете импровизацию.',
          minScore: 57,
          maxScore: 88,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы организованны, надёжны и нацелены на результат. '
              'Доводите начатое до конца и следуете высоким стандартам.',
          minScore: 89,
          maxScore: 120,
        ),
      ],
    ),
    'extraversion': ScoringScale(
      name: 'extraversion',
      label: 'Экстраверсия',
      description:
          'Отражает уровень активности, общительность, '
          'напористость и стремление к социальному взаимодействию.',
      minScore: 24,
      maxScore: 120,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы предпочитаете спокойную обстановку и глубокое '
              'общение с узким кругом людей. Восстанавливаете силы в одиночестве.',
          minScore: 24,
          maxScore: 56,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы амбиверт: комфортно чувствуете себя как в компании, '
              'так и наедине с собой. Гибко адаптируетесь к ситуации.',
          minScore: 57,
          maxScore: 88,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы энергичны, общительны и напористы. Получаете энергию '
              'от общения и любите быть в центре событий.',
          minScore: 89,
          maxScore: 120,
        ),
      ],
    ),
    'agreeableness': ScoringScale(
      name: 'agreeableness',
      label: 'Доброжелательность',
      description:
          'Отражает склонность к сотрудничеству, доверие, '
          'альтруизм и стремление к гармонии в отношениях.',
      minScore: 24,
      maxScore: 120,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы скептически относитесь к мотивам людей и отстаиваете '
              'свои интересы. Цените конкуренцию и прямое общение.',
          minScore: 24,
          maxScore: 56,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы умеете сотрудничать, но при необходимости отстаиваете '
              'свою позицию. Баланс между доверием и осторожностью.',
          minScore: 57,
          maxScore: 88,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы доверчивы, щедры и стремитесь к гармонии. '
              'Цените сотрудничество и готовы помогать другим.',
          minScore: 89,
          maxScore: 120,
        ),
      ],
    ),
    'neuroticism': ScoringScale(
      name: 'neuroticism',
      label: 'Нейротизм',
      description:
          'Отражает склонность к негативным эмоциям: тревоге, гневу, '
          'депрессии и уязвимости к стрессу.',
      minScore: 24,
      maxScore: 120,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы эмоционально устойчивы, спокойны и редко '
              'расстраиваетесь. Хорошо справляетесь со стрессом.',
          minScore: 24,
          maxScore: 56,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы испытываете нормальный диапазон эмоций. '
              'Иногда волнуетесь, но в целом справляетесь со стрессом.',
          minScore: 57,
          maxScore: 88,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы склонны к сильным негативным переживаниям. '
              'Стресс и неудачи могут сильно вас расстраивать.',
          minScore: 89,
          maxScore: 120,
        ),
      ],
    ),
  };

  // ---------------------------------------------------------------------------
  // Public getter
  // ---------------------------------------------------------------------------
  static PsychologicalTest get test => const PsychologicalTest(
        id: testId,
        title: 'Big Five (IPIP-120)',
        description:
            'Расширенный тест «Большая пятёрка» — 120 вопросов, оценивающих '
            'пять основных черт личности: Открытость, Добросовестность, '
            'Экстраверсию, Доброжелательность и Нейротизм. '
            'Каждая шкала включает по 4 аспекта. '
            'Лицензия: Public Domain. Источник: https://ipip.ori.org/',
        icon: 'psychology',
        category: 'personality',
        durationMinutes: 20,
        questions: _questions,
        scoringScales: _scoringScales,
      );
}
