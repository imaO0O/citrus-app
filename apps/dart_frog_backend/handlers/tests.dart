part of '../server.dart';

/// Метаданные всех доступных тестов (без вопросов)
Future<Response> _getAvailableTests(RequestContext context) async {
  try {
    final tests = [
      {
        'id': 'big_five_ipip_50',
        'title': 'Большая пятёрка (IPIP-50)',
        'description': '5 основных черт личности',
        'icon': '🧠',
        'category': 'personality',
        'questionsCount': 50,
        'durationMinutes': 10,
      },
      {
        'id': 'big_five_ipip_120',
        'title': 'Большая пятёрка (IPIP-120)',
        'description': 'Расширенный тест личности с аспектами',
        'icon': '🧠',
        'category': 'personality',
        'questionsCount': 120,
        'durationMinutes': 20,
      },
      {
        'id': 'phq9',
        'title': 'PHQ-9: Скрининг депрессии',
        'description': 'Оценка депрессивных симптомов',
        'icon': '📉',
        'category': 'clinical',
        'questionsCount': 9,
        'durationMinutes': 3,
      },
      {
        'id': 'gad7',
        'title': 'GAD-7: Скрининг тревожности',
        'description': 'Оценка симптомов тревоги',
        'icon': '😰',
        'category': 'clinical',
        'questionsCount': 7,
        'durationMinutes': 2,
      },
      {
        'id': 'dass21',
        'title': 'DASS-21: Депрессия, тревога, стресс',
        'description': 'Комплексная оценка эмоционального состояния',
        'icon': '📊',
        'category': 'clinical',
        'questionsCount': 21,
        'durationMinutes': 5,
      },
      {
        'id': 'rosenberg_self_esteem',
        'title': 'Шкала самооценки Розенберга',
        'description': 'Оценка уровня самооценки',
        'icon': '💪',
        'category': 'clinical',
        'questionsCount': 10,
        'durationMinutes': 3,
      },
      {
        'id': 'dark_triad_sd3',
        'title': 'Тёмная триада (SD3)',
        'description': 'Нарциссизм, макиавеллизм, психопатия',
        'icon': '🌑',
        'category': 'personality',
        'questionsCount': 27,
        'durationMinutes': 7,
      },
      {
        'id': 'disc',
        'title': 'DISC: Стиль поведения',
        'description': 'Доминирование, влияние, стабильность, добросовестность',
        'icon': '🎯',
        'category': 'behavioral',
        'questionsCount': 28,
        'durationMinutes': 10,
      },
    ];

    return Response.json(body: tests);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить полный тест с вопросами
Future<Response> _getTest(RequestContext context, String testId) async {
  // В production здесь загрузка из БД или файла
  // Пока возвращаем заглушку - клиент сам содержит все тесты
  return Response.json(body: {
    'id': testId,
    'message': 'Test questions are embedded in the client app',
  });
}

/// Отправить ответы теста и получить результат
Future<Response> _submitTest(
    RequestContext context, _AuthContext auth, String testId) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Читаем тело как строку с явным декодированием UTF-8
    final bodyStr = await context.request.body();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    
    final answers = body['answers'] as Map<String, dynamic>?;
    final completedAt = body['completedAt'] as String?;
    final interpretations = body['interpretations'] as Map<String, dynamic>?;

    if (answers == null || answers.isEmpty) {
      return Response(statusCode: 400, body: 'answers are required');
    }

    // Подсчёт баллов по шкалам
    final scores = <String, int>{};
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final answerValue = entry.value;
      
      // Безопасное приведение к int
      if (answerValue is int) {
        scores['question_${questionId}'] = answerValue;
      } else if (answerValue is num) {
        scores['question_${questionId}'] = answerValue.toInt();
      } else {
        print('Invalid answer value for $questionId: $answerValue');
      }
    }

    final recordId = const Uuid().v4();
    final scoresJson = jsonEncode(scores);
    final interpretationsJson = interpretations != null && interpretations.isNotEmpty
        ? jsonEncode(interpretations)
        : null;
    
    // Безопасный парсинг даты
    DateTime completedAtDate;
    try {
      completedAtDate = completedAt != null && completedAt.isNotEmpty
          ? DateTime.parse(completedAt)
          : DateTime.now();
    } catch (e) {
      print('Invalid date format: $completedAt, using current time');
      completedAtDate = DateTime.now();
    }

    print('Inserting test result: testId=$testId, userId=$userId, scores=$scoresJson');

    await _dbQuery(
      "INSERT INTO psychological_test_results (id, user_id, test_id, scores, interpretations, completed_at) "
      r"VALUES (@id, @userId, @testId, @scores, @interpretations, @completedAt)",
      substitutionValues: {
        'id': recordId,
        'userId': userId,
        'testId': testId,
        'scores': scoresJson,
        'interpretations': interpretationsJson,
        'completedAt': completedAtDate.toUtc(),
      },
    );

    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'testId': testId,
      'scores': scores,
      'completedAt': completedAtDate.toIso8601String(),
    });
  } catch (e, stackTrace) {
    print('Test submit error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить историю результатов тестов
Future<Response> _getTestResults(
    RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _dbQuery(
      'SELECT id, test_id, scores::text, interpretations::text, completed_at::text '
      'FROM psychological_test_results '
      'WHERE user_id = @userId '
      'ORDER BY completed_at DESC',
      substitutionValues: {'userId': userId},
    );

    final records = results.map((row) => {
          'id': row[0] is String
              ? row[0]
              : Uuid.unparse(row[0] as Uint8List),
          'testId': row[1],
          'scores': row[2],
          'interpretations': row[3],
          'completedAt': row[4],
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить результаты конкретного теста
Future<Response> _getTestResult(
    RequestContext context, _AuthContext auth, String testId) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _dbQuery(
      'SELECT id, test_id, scores::text, interpretations::text, completed_at::text '
      'FROM psychological_test_results '
      'WHERE user_id = @userId AND test_id = @testId '
      'ORDER BY completed_at DESC',
      substitutionValues: {'userId': userId, 'testId': testId},
    );

    final records = results.map((row) => {
          'id': row[0] is String
              ? row[0]
              : Uuid.unparse(row[0] as Uint8List),
          'testId': row[1],
          'scores': row[2],
          'interpretations': row[3],
          'completedAt': row[4],
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== TRUSTED CONTACTS CRUD ====================

