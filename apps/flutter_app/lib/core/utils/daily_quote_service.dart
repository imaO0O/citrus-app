import 'dart:math';

/// Сервис ежедневных аффирмаций
class DailyQuoteService {
  static const List<Map<String, String>> _quotes = [
    {
      'quote': 'Каждый день — это новая возможность стать лучше. Ты справишься!',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Ты сильнее, чем думаешь. Ты смелее, чем кажется.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Дыши. Ты уже прошёл через самое трудное.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Маленькие шаги ведут к большим переменам.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Ты заслуживаешь хорошего настроения и спокойствия.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Не бойся просить о помощи — это признак силы.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Твои чувства важны. Дай себе время.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Сегодня ты можешь начать сначала.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Заботься о себе — это не эгоизм, это необходимость.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'У тебя уже есть всё, чтобы быть счастливым.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Ты не один. Мы рядом.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Каждое дыхание — это шанс начать заново.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Позволь себе отдохнуть — это нормально.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Твоя история ещё не закончена.',
      'label': 'Аффирмация дня',
    },
    {
      'quote': 'Ты растёшь, даже если не замечаешь.',
      'label': 'Аффирмация дня',
    },
  ];

  /// Получить аффирмацию для конкретного дня
  Map<String, String> getQuoteForDate([DateTime? date]) {
    final day = date ?? DateTime.now();
    final dayOfYear = _dayOfYear(day);
    final index = dayOfYear % _quotes.length;
    return _quotes[index];
  }

  /// Случайная аффирмация
  Map<String, String> getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays;
  }
}
