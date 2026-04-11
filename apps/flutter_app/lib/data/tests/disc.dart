// DISC Assessment - стиль поведения
// Лицензия: Public Domain

import '../../../models/psychological_test.dart';

class DISCTest {
  static const testId = 'disc';

  static PsychologicalTest get test => PsychologicalTest(
        id: testId,
        title: 'DISC Assessment',
        description:
            'Оценка стиля поведения по модели DISC: доминирование, влияние, стабильность, добросовестность. Выберите наиболее подходящее утверждение для каждого вопроса.',
        icon: 'behavior',
        category: 'behavioral',
        durationMinutes: 10,
        questions: _questions,
        scoringScales: _scoringScales,
      );

  static const List<TestQuestion> _questions = [
    TestQuestion(
      id: 1,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Убедительный', 'Общительный', 'Спокойный', 'Точный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 2,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Решительный', 'Оптимистичный', 'Надёжный', 'Аналитичный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 3,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Прямой', 'Вдохновляющий', 'Добрый', 'Систематичный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 4,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Конкурентный', 'Обаятельный', 'Терпеливый', 'Осторожный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 5,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Целеустремлённый', 'Дружелюбный', 'Миролюбивый', 'Аккуратный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 6,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Смелый', 'Выразительный', 'Стабильный', 'Внимательный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 7,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Настойчивый', 'Общительный', 'Преданный', 'Организованный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 8,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Сильный', 'Разговорчивый', 'Тихий', 'Перфекционист'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 9,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Независимый', 'Энергичный', 'Скромный', 'Консервативный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 10,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Амбициозный', 'Энтузиаст', 'Согласный', 'Пунктуальный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 11,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Откровенный', 'Игривый', 'Уступчивый', 'Осторожный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 12,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Доминирующий', 'Влиятельный', 'Стабильный', 'Соответствующий'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 13,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Рискованный', 'Социальный', 'Предсказуемый', 'Подчиняющийся'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 14,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Требовательный', 'Убедительный', 'Спокойный', 'Тщательный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 15,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Предприимчивый', 'Популярный', 'Терпеливый', 'Скрупулёзный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 16,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Уверенный', 'Весёлый', 'Надёжный', 'Аккуратный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 17,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Твёрдый', 'Вдохновляющий', 'Дружелюбный', 'Дисциплинированный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 18,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Напористый', 'Общительный', 'Лояльный', 'Методичный'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 19,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Сильная воля', 'Идеалист', 'Терпеливый', 'Перфекционист'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 20,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Лидер', 'Мотиватор', 'Миротворец', 'Аналитик'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 21,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Пионер', 'Промоутер', 'Дипломат', 'Инспектор'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 22,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Авантюрист', 'Развлекатель', 'Советник', 'Планировщик'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 23,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Командир', 'Оратор', 'Посредник', 'Контролёр'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 24,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Инициатор', 'Оптимист', 'Поддержка', 'Архитектор'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 25,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Визионер', 'Дипломат', 'Хранитель', 'Эксперт'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 26,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Новатор', 'Посредник', 'Защитник', 'Исследователь'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 27,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Стратег', 'Увлечённый', 'Утешитель', 'Логик'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
    TestQuestion(
      id: 28,
      text: 'Какое слово лучше всего описывает вас?',
      options: ['Директор', 'Представитель', 'Гармонизатор', 'Систематизатор'],
      scoring: {'dominance': 1, 'influence': 1, 'steadiness': 1, 'conscientiousness': 1},
    ),
  ];

  static const Map<String, ScoringScale> _scoringScales = {
    'dominance': ScoringScale(
      name: 'dominance',
      label: 'Доминирование (D)',
      description:
          'Склонность к контролю над ситуацией, решительность, напористость',
      minScore: 0,
      maxScore: 28,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы предпочитаете сотрудничество и дипломатию, избегаете конфронтации, склонны к компромиссам.',
          minScore: 0,
          maxScore: 9,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы проявляете решительность, когда это необходимо, но также умеете слушать других и находить баланс.',
          minScore: 10,
          maxScore: 18,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы стремитесь к лидерству, принимаете решения уверенно и быстро, предпочитаете контролировать ситуацию.',
          minScore: 19,
          maxScore: 28,
        ),
      ],
    ),
    'influence': ScoringScale(
      name: 'influence',
      label: 'Влияние (I)',
      description:
          'Склонность влиять на других, общительность, энтузиазм',
      minScore: 0,
      maxScore: 28,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы предпочитаете работать в одиночку, сдержанны в общении, больше цените факты, чем эмоции.',
          minScore: 0,
          maxScore: 9,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы общительны, но знаете, когда стоит помолчать. Умеете убеждать, не навязывая своё мнение.',
          minScore: 10,
          maxScore: 18,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы энергичны, харизматичны, легко заводите знакомства и вдохновляете окружающих.',
          minScore: 19,
          maxScore: 28,
        ),
      ],
    ),
    'steadiness': ScoringScale(
      name: 'steadiness',
      label: 'Стабильность (S)',
      description:
          'Склонность к стабильности, терпение, преданность',
      minScore: 0,
      maxScore: 28,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы быстро адаптируетесь к переменам, ищите новые вызовы, не боитесь неопределённости.',
          minScore: 0,
          maxScore: 9,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы цените стабильность, но готовы к переменам, когда это необходимо. Надёжны и последовательны.',
          minScore: 10,
          maxScore: 18,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы цените предсказуемость и гармонию, верны своему окружению, предпочитаете стабильный темп работы.',
          minScore: 19,
          maxScore: 28,
        ),
      ],
    ),
    'conscientiousness': ScoringScale(
      name: 'conscientiousness',
      label: 'Добросовестность (C)',
      description:
          'Склонность к точности, организованность, качество',
      minScore: 0,
      maxScore: 28,
      interpretations: [
        ScoreInterpretation(
          level: 'low',
          label: 'Низкий',
          description:
              'Вы гибки и спонтанны, предпочитаете быстро действовать, не зацикливаясь на деталях.',
          minScore: 0,
          maxScore: 9,
        ),
        ScoreInterpretation(
          level: 'medium',
          label: 'Средний',
          description:
              'Вы внимательны к деталям, но знаете меру. Стремитесь к качеству, сохраняя продуктивность.',
          minScore: 10,
          maxScore: 18,
        ),
        ScoreInterpretation(
          level: 'high',
          label: 'Высокий',
          description:
              'Вы перфекционист, цените точность и порядок. Следуете правилам и стандартам, стремитесь к безупречности.',
          minScore: 19,
          maxScore: 28,
        ),
      ],
    ),
  };
}
