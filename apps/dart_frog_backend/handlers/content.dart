part of '../server.dart';

// Wikipedia API конфигурация для статей ментального здоровья (русский)
const _wikipediaTopicsRu = {
  'anxiety': '%D0%A2%D1%80%D0%B5%D0%B2%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D1%8C',
  'depression': '%D0%94%D0%B5%D0%BF%D1%80%D0%B5%D1%81%D1%81%D0%B8%D1%8F',
  'sleep': '%D0%93%D0%B8%D0%B3%D0%B8%D0%B5%D0%BD%D0%B0_%D1%81%D0%BD%D0%B0',
  'stress': '%D0%A1%D1%82%D1%80%D0%B5%D1%81%D1%81',
  'self-esteem': '%D0%A1%D0%B0%D0%BC%D0%BE%D0%BE%D1%86%D0%B5%D0%BD%D0%BA%D0%B0',
  'relationships': '%D0%9C%D0%B5%D0%B6%D0%BB%D0%B8%D1%87%D0%BD%D0%BE%D1%81%D1%82%D0%BD%D1%8B%D0%B5_%D0%BE%D1%82%D0%BD%D0%BE%D1%88%D0%B5%D0%BD%D0%B8%D1%8F',
  'mindfulness': '%D0%9E%D1%81%D0%BE%D0%B7%D0%BD%D0%B0%D0%BD%D0%BD%D0%BE%D1%81%D1%82%D1%8C_(%D0%BF%D1%81%D0%B8%D1%85%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D1%8F)',
  'panic_attacks': '%D0%9F%D0%B0%D0%BD%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F_%D0%B0%D1%82%D0%B0%D0%BA%D0%B0',
  'burnout': '%D0%AD%D0%BC%D0%BE%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D0%B2%D1%8B%D0%B3%D0%BE%D1%80%D0%B0%D0%BD%D0%B8%D0%B5',
  'meditation': '%D0%9C%D0%B5%D0%B4%D0%B8%D1%82%D0%B0%D1%86%D0%B8%D1%8F',
  'cognitive_behavioral_therapy': '%D0%9A%D0%BE%D0%B3%D0%BD%D0%B8%D1%82%D0%B8%D0%B2%D0%BD%D0%BE-%D0%BF%D0%BE%D0%B2%D0%B5%D0%B4%D0%B5%D0%BD%D1%87%D0%B5%D1%81%D0%BA%D0%B0%D1%8F_%D0%BF%D1%81%D0%B8%D1%85%D0%BE%D1%82%D0%B5%D1%80%D0%B0%D0%BF%D0%B8%D1%8F',
  'loneliness': '%D0%9E%D0%B4%D0%B8%D0%BD%D0%BE%D1%87%D0%B5%D1%81%D1%82%D0%B2%D0%BE',
  'anger': '%D0%93%D0%BD%D0%B5%D0%B2',
  'self_care': '%D0%A1%D0%B0%D0%BC%D0%BE%D0%BF%D0%BE%D0%BC%D0%BE%D1%89%D1%8C',
  'emotional_intelligence': '%D0%AD%D0%BC%D0%BE%D1%86%D0%B8%D0%BE%D0%BD%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9_%D0%B8%D0%BD%D1%82%D0%B5%D0%BB%D0%BB%D0%B5%D0%BA%D1%82',
};

const _wikipediaTitlesRu = {
  'anxiety': 'Тревожность',
  'depression': 'Депрессия',
  'sleep': 'Гигиена сна',
  'stress': 'Стресс',
  'self-esteem': 'Самооценка',
  'relationships': 'Межличностные отношения',
  'mindfulness': 'Осознанность',
  'panic_attacks': 'Паническая атака',
  'burnout': 'Эмоциональное выгорание',
  'meditation': 'Медитация',
  'cognitive_behavioral_therapy': 'Когнитивно-поведенческая терапия',
  'loneliness': 'Одиночество',
  'anger': 'Гнев',
  'self_care': 'Самопомощь',
  'emotional_intelligence': 'Эмоциональный интеллект',
};

const _wikipediaCategoryMap = {
  'anxiety': 'anxiety',
  'depression': 'depression',
  'sleep': 'sleep',
  'stress': 'stress',
  'self-esteem': 'self-esteem',
  'relationships': 'relationships',
  'mindfulness': 'mindfulness',
  'panic_attacks': 'anxiety',
  'burnout': 'stress',
  'meditation': 'mindfulness',
  'cognitive_behavioral_therapy': 'stress',
  'loneliness': 'depression',
  'anger': 'stress',
  'self_care': 'mindfulness',
  'emotional_intelligence': 'relationships',
};

// Кэш Wikipedia статей
Map<String, Map<String, dynamic>> _wikipediaCache = {};
DateTime? _wikipediaCacheTime;
/// POST /chat - чат с GigaChat AI
Future<Response> _chatWithAI(RequestContext context) async {
  // Проверяем, инициализирован ли GigaChat сервис
  if (_gigachatService == null) {
    return Response.json(
      statusCode: 503,
      body: {
        'error': 'GigaChat service is not configured',
        'message': 'Установите переменные окружения GIGACHAT_AUTHORIZATION_KEY',
      },
    );
  }

  try {
    final body = await context.request.json();
    final message = body['message'] as String?;
    final systemPrompt = body['system_prompt'] as String?;
    final temperature = (body['temperature'] as num?)?.toDouble() ?? 0.7;
    final maxTokens = body['max_tokens'] as int? ?? 2048; // Увеличено для аналитики

    if (message == null || message.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'message is required'},
      );
    }

    // Получаем userId из токена (если есть авторизация)
    String? userId;
    final token = _extractToken(context);
    if (token != null) {
      try {
        final jwt = JWT.verify(token, SecretKey(_jwtSecret));
        userId = jwt.payload['user_id'] as String?;
      } catch (_) {}
    }

    // Определяем system prompt
    String finalSystemPrompt = systemPrompt ?? 'Ты полезный ассистент по имени Цитрус. Ты помогаешь пользователям следить за своим ментальным здоровьем, даёшь советы по улучшению настроения, борьбе с тревогой и поддержанию хорошего эмоционального состояния. Отвечай дружелюбно и поддерживающе. Используй Markdown: **жирный** для ключевых моментов, *курсив* для акцентов.';
    
    // Если сообщение содержит аналитику, адаптируем prompt
    if (message.contains('📊') && message.contains('Аналитика')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе свою аналитику настроения и активности. 
Проанализируй данные, дай полезные инсайты и поддерживающий комментарий. 
Обращай внимание на тренды, серийность дней и распределение настроения.
Будь конкретным и давай практические рекомендации.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.''';
    } else if (message.contains('📓') && message.contains('Записи дневника')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе свои записи из дневника.

ВАЖНО: Проанализируй именно СОДЕРЖАНИЕ каждой записи. Обращай внимание на:
1. Конкретные события и действия, которые описывает пользователь
2. Эмоции и чувства, которые он выражает
3. Повторяющиеся темы, слова или ситуации в разных записях
4. Есть ли связь между настроением и содержанием записей
5. Позитивные моменты и достижения
6. Возможные источники стресса или тревоги

ДАЙ КОНКРЕТНЫЙ анализ: упоминай события, детали и фразы из записей пользователя.
НЕ пиши общие фразы типа "записи краткие" или "нет детализации" — работай с тем что есть.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.
Будь тёплым, поддерживающим и конкретным.''';
    } else if (message.contains('😴') && message.contains('Анализ сна')) {
      finalSystemPrompt = '''Ты Цитрус — AI-ассистент для ментального здоровья. Пользователь отправил тебе данные о своём сне.
Проанализируй качество сна, дай рекомендации по улучшению гигиены сна и объясни как сон влияет на ментальное здоровье.
Используй Markdown: **жирный текст** для ключевых выводов, *курсив* для акцентов.''';
    }

    // Отправляем сообщение в GigaChat
    final startTime = DateTime.now();
    final response = await _gigachatService!.chat(
      message,
      systemPrompt: finalSystemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    final responseTime = DateTime.now().difference(startTime).inMilliseconds;

    // Сохраняем сообщения в БД (если пользователь авторизован)
    if (userId != null && _db != null) {
      try {
        final msgId = const Uuid().v4();
        final escapedUser = message.replaceAll("'", "''");
        final escapedResponse = response.replaceAll("'", "''");
        await _dbQuery(
          """
          INSERT INTO chat_messages 
          (id, user_id, user_message, ai_response, created_at, response_time_ms, model_used)
          VALUES 
          ('$msgId', '$userId', '$escapedUser', '$escapedResponse', NOW(), $responseTime, 'GigaChat')
          """,
        );
      } catch (e) {
        print('Warning: failed to save chat message: $e');
      }
    }

    return Response.json(
      statusCode: 200,
      body: {
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    print('Error in /chat endpoint: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to get AI response: $e'},
    );
  }
}

/// GET /chat/messages - получить историю сообщений пользователя
Future<Response> _getChatMessages(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _dbQuery(
      '''SELECT id, user_message, ai_response, created_at 
         FROM chat_messages 
         WHERE user_id = '$userId' 
         ORDER BY created_at DESC 
         LIMIT 100''',
    );

    final messages = result.map((row) => {
      'id': row[0] as String,
      'user_message': row[1] as String,
      'ai_response': row[2] as String,
      'created_at': (row[3] as DateTime).toIso8601String(),
    }).toList();

    return Response.json(body: messages);
  } catch (e) {
    // Если таблица ещё не создана, возвращаем пустой список
    return Response.json(body: <Map<String, dynamic>>[]);
  }
}

/// Загрузить статьи из Wikipedia API (русский)
Future<List<Map<String, dynamic>>> _getWikipediaArticles() async {
  // Проверяем кэш
  final now = DateTime.now();
  if (_wikipediaCache.isNotEmpty &&
      _wikipediaCacheTime != null &&
      now.difference(_wikipediaCacheTime!).inMinutes < _cacheDurationMinutes) {
    return _wikipediaCache.values.toList();
  }

  _wikipediaCache.clear();

  for (final entry in _wikipediaTopicsRu.entries) {
    final wikiKey = entry.key;
    final wikiTitle = entry.value;
    final category = _wikipediaCategoryMap[wikiKey] ?? 'mindfulness';
    final displayTitle = _wikipediaTitlesRu[wikiKey] ?? wikiKey;

    try {
      final url = Uri.parse(
        'https://ru.wikipedia.org/api/rest_v1/page/html/$wikiTitle',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'CitrusApp/1.0 (mental health app)',
        'Accept': 'text/html',
      });

      if (response.statusCode == 200) {
        final html = response.body;
        final markdownContent = _htmlToMarkdown(html);

        if (markdownContent.isNotEmpty && markdownContent.length > 100) {
          final wikiArticle = {
            'id': 'wiki_$wikiKey',
            'user_id': null,
            'title': displayTitle,
            'content': markdownContent,
            'category': category,
            'is_custom': false,
            'created_at': now.toIso8601String(),
            'source': 'wikipedia',
            'tags': [category],
          };
          _wikipediaCache[wikiKey] = wikiArticle;
          print('Wikipedia: загружена статья "$displayTitle" (${markdownContent.length} символов)');
        }
      } else {
        print('Wikipedia: ошибка ${response.statusCode} для $wikiKey');
      }
    } catch (e) {
      print('Wikipedia API error for $wikiKey: $e');
    }

    // Задержка чтобы не спамить API
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Добавляем локальные системные статьи
  final localArticles = _getLocalArticles(now);
  for (final article in localArticles) {
    _wikipediaCache[article['id'] as String] = article;
  }

  _wikipediaCacheTime = now;
  print('Wikipedia: всего загружено ${_wikipediaCache.length} статей');
  return _wikipediaCache.values.toList();
}

/// Локальные системные статьи на русском
List<Map<String, dynamic>> _getLocalArticles(DateTime now) {
  return [
    {
      'id': 'local_breathing',
      'user_id': null,
      'title': 'Дыхательные техники для снятия тревоги',
      'content': '''## Дыхание 4-7-8

Эта техника помогает быстро успокоиться и снижает уровень тревоги.

**Как выполнять:**

1. Вдох через нос на **4 счёта**
2. Задержка дыхания на **7 счётов**
3. Медленный выдох через рот на **8 счётов**
4. Повторите 4 цикла

## Квадратное дыхание

Помогает сосредоточиться и снизить стресс.

**Техника:**

- Вдох на 4 счёта
- Задержка на 4 счёта
- Выдох на 4 счёта
- Задержка на 4 счёта
- Повторите 5-10 раз

## Почему это работает

Глубокое дыхание активирует **парасимпатическую нервную систему**, которая отвечает за расслабление. Это снижает уровень кортизола и адреналина в крови.

> **Совет:** Практикуйте дыхательные техники 2-3 раза в день, даже когда не испытываете тревогу. Это поможет закрепить навык.''',
      'category': 'anxiety',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['anxiety'],
    },
    {
      'id': 'local_sleep_tips',
      'user_id': null,
      'title': '10 советов для здорового сна',
      'content': '''## Как улучшить качество сна

### 1. Ложитесь и вставайте в одно время
Даже в выходные. Это настраивает ваши **циркадные ритмы**.

### 2. Создайте ритуал перед сном
- Тёплый душ или ванна
- Чтение книги (не экран!)
- Медитация или дыхательные упражнения

### 3. Оптимизируйте спальню
- Температура: **18-20°C**
- Полная темнота
- Тишина или белый шум

### 4. Ограничьте экраны перед сном
Голубой свет экранов подавляет **мелатонин**. За 1-2 часа до сна уберите телефон и компьютер.

### 5. Не ешьте тяжёлую пищу за 3 часа до сна
Пищеварение мешает организму расслабиться.

### 6. Ограничьте кофеин
Не пейте кофе, чай или энергетики после **14:00**. Кофеин действует до 8 часов.

### 7. Физическая активность
Регулярные упражнения улучшают качество сна, но не тренируйтесь за 3 часа до сна.

### 8. Не смотрите на часы
Если не можете уснуть — встаньте и займитесь чем-то спокойным 20 минут.

### 9. Ограничьте дневной сон
Если спите днём — не более **20-30 минут** до 15:00.

### 10. Записывайте мысли перед сном
Заведите **дневник тревог**. Запишите все беспокоящие мысли — это освободит голову.

---
*На основе рекомендаций Национального фонда сна (NSF)*''',
      'category': 'sleep',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['sleep'],
    },
    {
      'id': 'local_stress_management',
      'user_id': null,
      'title': 'Управление стрессом: практические техники',
      'content': '''## Что такое стресс

**Стресс** — это естественная реакция организма на вызовы и угрозы. Кратковременный стресс может быть полезным, но хронический стресс разрушительно влияет на здоровье.

## Техника заземления 5-4-3-2-1

Когда вас захлёстывает стресс, используйте этот метод:

- **5** вещей, которые вы **видите**
- **4** вещи, которые вы можете **потрогать**
- **3** вещи, которые вы **слышите**
- **2** вещи, которые вы можете **понюхать**
- **1** вещь, которую вы можете **попробовать на вкус**

## Прогрессивная мышечная релаксация

Поочерёдно напрягайте и расслабляйте группы мышц:

1. Начните с **кулаков** — сожмите на 5 секунд, расслабьте
2. Перейдите к **бицепсам**
3. Затем **плечи**, **спина**, **пресс**
4. Закончите **ногами** и **ступнями**

## Когнитивная реструктуризация

Записывайте негативные мысли и оспаривайте их:

| Автоматическая мысль | Реальность |
|---|---|
| "У меня ничего не получится" | "Раньше я справлялся с трудностями" |
| "Все против меня" | "Есть люди, которые меня поддерживают" |

## Когда обращаться за помощью

Если стресс мешает повседневной жизни более **2 недель**, обратитесь к специалисту.

---
*На основе методов когнитивно-поведенческой терапии*''',
      'category': 'stress',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['stress'],
    },
    {
      'id': 'local_self_esteem',
      'user_id': null,
      'title': 'Как повысить самооценку: 7 шагов',
      'content': '''## Что такое самооценка

**Самооценка** — это то, как мы оцениваем себя, свои качества и возможности. Здоровая самооценка — основа ментального благополучия.

## 7 практических шагов

### 1. Отслеживайте внутреннего критика
Замечайте негативные мысли о себе. Запишите их и спросите: *"Это факт или моё мнение?"*

### 2. Практикуйте самосострадание
Относитесь к себе так, как относились бы к **другу** в трудной ситуации.

### 3. Отмечайте достижения
Каждый вечер записывайте **3 вещи**, которыми вы гордитесь сегодня. Даже маленькие.

### 4. Установите границы
Научитесь говорить **«нет»** тому, что истощает вас.

### 5. Перестаньте сравнивать себя с другими
Социальные сети показывают только «лучшую» сторону жизни других людей.

### 6. Заботьтесь о теле
- Регулярная физическая активность
- Здоровое питание
- Достаточно сна

### 7. Окружите себя поддерживающими людьми
Минимизируйте общение с теми, кто вас обесценивает.

> **Помните:** Самооценка — это навык, который можно развить. Это не фиксированная черта.

---
*На основе работ Кристин Нефф о самосострадании*''',
      'category': 'self-esteem',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['self-esteem'],
    },
    {
      'id': 'local_mindfulness',
      'user_id': null,
      'title': 'Осознанность для начинающих',
      'content': '''## Что такое осознанность

**Осознанность (mindfulness)** — это способность присутствовать в текущем моменте, замечать свои мысли, чувства и ощущения без осуждения.

## Простая медитация на 5 минут

### Инструкция

1. Сядьте удобно, спина прямая
2. Закройте глаза или опустите взгляд
3. Сосредоточьтесь на **дыхании**
4. Замечайте, как воздух входит и выходит
5. Когда ум блуждает — мягко верните внимание к дыханию
6. Начните с **5 минут**, постепенно увеличивая

## Осознанность в повседневности

### Осознанное питание
- Ешьте медленно
- Замечайте вкус, текстуру, запах каждого кусочка
- Отложите приборы между кусочками

### Осознанная ходьба
- Замечайте, как стопы касаются земли
- Ощущайте вес тела
- Замечайте движение воздуха на коже

### Осознанное слушание
- Слушайте звуки вокруг без оценки
- Замечайте тишину между звуками
- Не пытайтесь интерпретировать

## Научные данные

Исследования показывают, что регулярная практика осознанности:

- Снижает уровень **кортизола** на 25%
- Улучшает концентрацию внимания
- Уменьшает симптомы тревоги и депрессии
- Повышает качество сна

> **«Вы не можете остановить волны, но вы можете научиться сёрфингу»** — Джон Кабат-Зинн

---
*На основе программы MBSR Джона Кабат-Зинна*''',
      'category': 'mindfulness',
      'is_custom': false,
      'created_at': now.toIso8601String(),
      'source': 'app',
      'tags': ['mindfulness'],
    },
  ];
}

/// GET /articles — получить все статьи пользователя + системные + Wikipedia
Future<Response> _getArticles(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Загружаем статьи из БД
    final results = await _dbQuery(
      "SELECT id, user_id, title, content, category, is_custom, source, tags, created_at FROM articles WHERE user_id = '$userId' OR user_id IS NULL ORDER BY created_at DESC",
    );

    final articles = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
        'title': row[2],
        'content': row[3],
        'category': row[4],
        'is_custom': row[5],
        'source': row[6],
        'tags': row[7],
        'created_at': row[8].toString(),
      };
    }).toList();

    // Добавляем Wikipedia статьи
    final wikiArticles = await _getWikipediaArticles();
    articles.addAll(wikiArticles);

    return Response.json(body: articles);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// POST /articles — создать статью
Future<Response> _createArticle(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final title = body['title'] as String?;
  final content = body['content'] as String?;
  final category = body['category'] as String? ?? 'custom';

  if (title == null || title.isEmpty || content == null || content.isEmpty) {
    return Response(statusCode: 400, body: 'title and content are required');
  }

  try {
    final articleId = const Uuid().v4();
    final titleSql = title.replaceAll("'", "''");
    final contentSql = content.replaceAll("'", "''");
    final categorySql = category.replaceAll("'", "''");

    final result = await _dbQuery(
      "INSERT INTO articles (id, user_id, title, content, category, is_custom) VALUES ('$articleId', '$userId', '$titleSql', '$contentSql', '$categorySql', true) RETURNING id, user_id, title, content, category, is_custom, source, tags, created_at",
    );

    final row = result.first;
    return Response.json(
      statusCode: 201,
      body: {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
        'title': row[2],
        'content': row[3],
        'category': row[4],
        'is_custom': row[5],
        'source': row[6],
        'tags': row[7],
        'created_at': row[8].toString(),
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// PUT /articles/{id} — обновить статью
Future<Response> _updateArticle(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final title = body['title'] as String?;
  final content = body['content'] as String?;
  final category = body['category'] as String?;

  if (title == null && content == null && category == null) {
    return Response(statusCode: 400, body: 'At least one field must be provided');
  }

  try {
    final titleSql = title != null ? "'${title.replaceAll("'", "''")}'" : null;
    final contentSql = content != null ? "'${content.replaceAll("'", "''")}'" : null;
    final categorySql = category != null ? "'${category.replaceAll("'", "''")}'" : null;

    // Проверяем, что статья принадлежит пользователю
    final checkResult = await _dbQuery(
      "SELECT title, content, category FROM articles WHERE id = '$id' AND user_id = '$userId'",
    );

    if (checkResult.isEmpty) {
      return Response(statusCode: 404, body: 'Article not found or not owned by user');
    }

    final currentRow = checkResult.first;
    final finalTitle = titleSql ?? "'${(currentRow[0] as String).replaceAll("'", "''")}'";
    final finalContent = contentSql ?? "'${(currentRow[1] as String).replaceAll("'", "''")}'";
    final finalCategory = categorySql ?? "'${(currentRow[2] as String).replaceAll("'", "''")}'";

    final result = await _dbQuery(
      "UPDATE articles SET title = $finalTitle, content = $finalContent, category = $finalCategory WHERE id = '$id' AND user_id = '$userId' RETURNING id, user_id, title, content, category, is_custom, source, tags, created_at",
    );

    final row = result.first;
    return Response.json(body: {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] != null ? (row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List)) : null,
      'title': row[2],
      'content': row[3],
      'category': row[4],
      'is_custom': row[5],
      'source': row[6],
      'tags': row[7],
      'created_at': row[8].toString(),
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// DELETE /articles/{id} — удалить статью
Future<Response> _deleteArticle(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final result = await _dbQuery(
      "DELETE FROM articles WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Article not found or not owned by user');
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

