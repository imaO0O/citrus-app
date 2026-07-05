part of '../server.dart';

/// POST /exercises/complete - отметить упражнение как выполненное
Future<Response> _completeExercise(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.body();
    final data = json.decode(body);

    final exerciseId = data['exercise_id'] as String?;
    final exerciseType = data['exercise_type'] as String?;
    final title = data['title'] as String?;
    final durationMinutes = data['duration_minutes'] as int?;
    final difficultyLevel = data['difficulty_level'] as int?;
    final userNotes = data['user_notes'] as String?;
    final moodBefore = data['mood_before'] as int?;
    final moodAfter = data['mood_after'] as int?;

    if (exerciseId == null || exerciseType == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'exercise_id and exercise_type are required'},
      );
    }

    final id = const Uuid().v4();
    await _dbQuery(
      'INSERT INTO user_exercises '
      '(id, user_id, exercise_id, exercise_type, title, duration_minutes, difficulty_level, user_notes, mood_before, mood_after, completed_at) '
      'VALUES (@id, @userId, @exerciseId, @exerciseType, @title, @duration, @difficulty, @userNotes, @moodBefore, @moodAfter, NOW())',
      substitutionValues: {
        'id': id,
        'userId': userId,
        'exerciseId': exerciseId,
        'exerciseType': exerciseType,
        'title': title,
        'duration': durationMinutes,
        'difficulty': difficultyLevel,
        'userNotes': userNotes,
        'moodBefore': moodBefore,
        'moodAfter': moodAfter,
      },
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': id,
        'message': 'Exercise completed successfully',
      },
    );
  } catch (e) {
    print('Error completing exercise: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
  }
}

/// GET /exercises/stats - расширенная статистика упражнений
Future<Response> _getExerciseStats(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Общая статистика
    int totalExercises = 0;
    int totalMinutes = 0;
    Map<String, int> byType = {};
    int last7Days = 0;
    int last30Days = 0;

    final sv = {'userId': userId};

    // Общее количество упражнений
    final totalResult = await _dbQuery(
      'SELECT COUNT(*) FROM user_exercises WHERE user_id = @userId',
      substitutionValues: sv,
    );
    totalExercises = int.parse(totalResult.first[0].toString());

    // Общее время
    final minutesResult = await _dbQuery(
      'SELECT COALESCE(SUM(duration_minutes), 0) FROM user_exercises WHERE user_id = @userId',
      substitutionValues: sv,
    );
    totalMinutes = int.parse(minutesResult.first[0].toString());

    // Группировка по типам
    final typeResult = await _dbQuery(
      'SELECT exercise_type, COUNT(*) FROM user_exercises WHERE user_id = @userId GROUP BY exercise_type',
      substitutionValues: sv,
    );
    for (final row in typeResult) {
      byType[row[0].toString()] = int.parse(row[1].toString());
    }

    // За последние 7 дней
    final last7Result = await _dbQuery(
      "SELECT COUNT(*) FROM user_exercises WHERE user_id = @userId AND completed_at > NOW() - INTERVAL '7 days'",
      substitutionValues: sv,
    );
    last7Days = int.parse(last7Result.first[0].toString());

    // За последние 30 дней
    final last30Result = await _dbQuery(
      "SELECT COUNT(*) FROM user_exercises WHERE user_id = @userId AND completed_at > NOW() - INTERVAL '30 days'",
      substitutionValues: sv,
    );
    last30Days = int.parse(last30Result.first[0].toString());

    // Средняя продолжительность
    double avgDuration = 0;
    final avgResult = await _dbQuery(
      'SELECT AVG(duration_minutes) FROM user_exercises WHERE user_id = @userId AND duration_minutes IS NOT NULL',
      substitutionValues: sv,
    );
    if (avgResult.first[0] != null) {
      avgDuration = double.parse(avgResult.first[0].toString());
    }

    return Response.json(body: {
      'totalExercises': totalExercises,
      'totalMinutes': totalMinutes,
      'byType': byType,
      'last7Days': last7Days,
      'last30Days': last30Days,
      'averageDurationMinutes': avgDuration.roundToDouble(),
    });
  } catch (e) {
    print('Error in /exercises/stats: $e');
    return Response.json(
      statusCode: 200,
      body: {
        'totalExercises': 0,
        'totalMinutes': 0,
        'byType': {},
        'last7Days': 0,
        'last30Days': 0,
        'averageDurationMinutes': 0,
      },
    );
  }
}

/// GET /exercises - история выполненных упражнений
Future<Response> _getExercises(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final queryParameters = context.request.uri.queryParameters;
    final limit = int.tryParse(queryParameters['limit'] ?? '50') ?? 50;
    final offset = int.tryParse(queryParameters['offset'] ?? '0') ?? 0;
    final exerciseType = queryParameters['type'];

    final sv = <String, dynamic>{'userId': userId};
    var whereClause = 'WHERE user_id = @userId';
    if (exerciseType != null) {
      whereClause += ' AND exercise_type = @type';
      sv['type'] = exerciseType;
    }

    final results = await _dbQuery(
      'SELECT id, exercise_id, exercise_type, title, completed_at, duration_minutes, difficulty_level, user_notes, mood_before, mood_after '
      'FROM user_exercises '
      '$whereClause '
      'ORDER BY completed_at DESC '
      'LIMIT @limit OFFSET @offset',
      substitutionValues: {...sv, 'limit': limit, 'offset': offset},
    );

    final exercises = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'exercise_id': row[1],
        'exercise_type': row[2],
        'title': row[3],
        'completed_at': row[4].toString(),
        'duration_minutes': row[5],
        'difficulty_level': row[6],
        'user_notes': row[7],
        'mood_before': row[8],
        'mood_after': row[9],
      };
    }).toList();

    // Получаем общее количество для пагинации
    final countResult = await _dbQuery(
      'SELECT COUNT(*) FROM user_exercises $whereClause',
      substitutionValues: sv,
    );
    final total = int.parse(countResult.first[0].toString());

    return Response.json(body: {
      'exercises': exercises,
      'total': total,
      'limit': limit,
      'offset': offset,
    });
  } catch (e) {
    print('Error in /exercises: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
  }
}
