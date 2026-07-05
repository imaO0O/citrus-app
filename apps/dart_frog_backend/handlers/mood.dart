part of '../server.dart';

Future<Response> _getMoodRecords(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final query = context.request.uri.queryParameters;
    final startDate = query['start_date'];
    final endDate = query['end_date'];

    final sv = <String, dynamic>{'userId': userId};
    var whereClause = 'WHERE user_id = @userId';
    if (startDate != null) {
      whereClause += ' AND DATE(recorded_at) >= CAST(@startDate AS date)';
      sv['startDate'] = startDate;
    }
    if (endDate != null) {
      whereClause += ' AND DATE(recorded_at) <= CAST(@endDate AS date)';
      sv['endDate'] = endDate;
    }

    final results = await _dbQuery(
      'SELECT id, user_id, mood_value, recorded_at::text '
      'FROM mood_entries $whereClause ORDER BY recorded_at DESC',
      substitutionValues: sv,
    );

    final records = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'mood_id': row[2] as int,
      'mood_date': row[3],
    }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createMoodRecord(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final moodId = body['mood_id'] as int?;
    final moodDate = body['mood_date'] as String?;
    final note = body['note'] as String?;

    if (moodId == null) {
      return Response(statusCode: 400, body: 'mood_id is required');
    }

    final recordId = const Uuid().v4();
    final timeOfDay = moodDate != null ? _getTimeOfDay(moodDate) : null;

    if (moodDate != null) {
      final recordedAt = DateTime.tryParse(moodDate) ?? DateTime.now();
      await _dbQuery(
        'INSERT INTO mood_entries (id, user_id, mood_value, time_of_day, recorded_at) '
        'VALUES (@id, @userId, @mood, @tod, @recordedAt)',
        substitutionValues: {
          'id': recordId,
          'userId': userId,
          'mood': moodId,
          'tod': timeOfDay,
          'recordedAt': recordedAt,
        },
      );
    } else {
      await _dbQuery(
        'INSERT INTO mood_entries (id, user_id, mood_value, time_of_day) '
        'VALUES (@id, @userId, @mood, @tod)',
        substitutionValues: {
          'id': recordId,
          'userId': userId,
          'mood': moodId,
          'tod': timeOfDay,
        },
      );
    }

    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'user_id': userId,
      'mood_id': moodId,
      'mood_date': moodDate ?? DateTime.now().toIso8601String(),
      'note': note,
    });
  } catch (e, stackTrace) {
    print('mood create error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateMoodRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final moodId = body['mood_id'] as int?;

    if (moodId == null) {
      return Response(statusCode: 400, body: 'mood_id is required');
    }

    await _dbQuery(
      'UPDATE mood_entries SET mood_value = @mood WHERE id = @id AND user_id = @userId',
      substitutionValues: {'mood': moodId, 'id': id, 'userId': userId},
    );

    return Response.json(body: {'id': id, 'mood_id': moodId});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteMoodRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    await _dbQuery(
      'DELETE FROM mood_entries WHERE id = @id AND user_id = @userId',
      substitutionValues: {'id': id, 'userId': userId},
    );
    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
