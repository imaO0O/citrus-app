part of '../server.dart';

/// Получить записи сна
Future<Response> _getSleepRecords(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final startDate = context.request.uri.queryParameters['start_date'] ?? '2020-01-01';
  final endDate = context.request.uri.queryParameters['end_date'] ?? '2030-12-31';

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _dbQuery(
      'SELECT id, user_id, sleep_date, '
      'bed_time::text as bed_time, '
      'wake_time::text as wake_time, '
      'quality '
      'FROM sleep_records '
      'WHERE user_id = @userId '
      'AND sleep_date >= CAST(@startDate AS date) '
      'AND sleep_date <= CAST(@endDate AS date) '
      'ORDER BY sleep_date DESC',
      substitutionValues: {'userId': userId, 'startDate': startDate, 'endDate': endDate},
    );

    final records = results.map((row) {
      final id = row[0];
      final userId = row[1];
      final sleepDate = row[2];
      final bedTime = row[3];
      final wakeTime = row[4];
      final quality = row[5];

      String? bedTimeStr;
      if (bedTime != null) {
        bedTimeStr = bedTime is String ? bedTime : String.fromCharCodes(bedTime as List<int>);
      }

      String? wakeTimeStr;
      if (wakeTime != null) {
        wakeTimeStr = wakeTime is String ? wakeTime : String.fromCharCodes(wakeTime as List<int>);
      }

      return {
        'id': id is String ? id : Uuid.unparse(id as Uint8List),
        'user_id': userId is String ? userId : Uuid.unparse(userId as Uint8List),
        'sleep_date': (sleepDate as DateTime).toIso8601String().split('T').first,
        'bed_time': bedTimeStr != null && bedTimeStr.isNotEmpty ? bedTimeStr : null,
        'wake_time': wakeTimeStr != null && wakeTimeStr.isNotEmpty ? wakeTimeStr : null,
        'quality': quality is int ? quality : null,
      };
    }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Создать запись сна
Future<Response> _createSleepRecord(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final sleepDate = body['sleep_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (sleepDate == null) {
    return Response(statusCode: 400, body: 'sleep_date is required');
  }

  final sleepDt = DateTime.tryParse(sleepDate);
  if (sleepDt == null) {
    return Response(statusCode: 400, body: 'invalid sleep_date');
  }

  try {
    final recordId = const Uuid().v4();
    final bedTime = body['bed_time'] as String?;
    final wakeTime = body['wake_time'] as String?;
    final quality = body['quality'] as int?;

    await _dbQuery(
      'INSERT INTO sleep_records (id, user_id, sleep_date, bed_time, wake_time, quality) '
      'VALUES (@id, @userId, @sleepDate, CAST(@bedTime AS time), CAST(@wakeTime AS time), @quality)',
      substitutionValues: {
        'id': recordId,
        'userId': userId,
        'sleepDate': sleepDt,
        'bedTime': (bedTime != null && bedTime.isNotEmpty) ? bedTime : null,
        'wakeTime': (wakeTime != null && wakeTime.isNotEmpty) ? wakeTime : null,
        'quality': quality,
      },
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': recordId,
        'user_id': userId,
        'sleep_date': sleepDate,
        'bed_time': bedTime,
        'wake_time': wakeTime,
        'quality': quality,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить запись сна
Future<Response> _updateSleepRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final sleepDate = body['sleep_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (sleepDate == null) {
    return Response(statusCode: 400, body: 'sleep_date is required');
  }

  final sleepDt = DateTime.tryParse(sleepDate);
  if (sleepDt == null) {
    return Response(statusCode: 400, body: 'invalid sleep_date');
  }

  try {
    final bedTime = body['bed_time'] as String?;
    final wakeTime = body['wake_time'] as String?;
    final quality = body['quality'] as int?;

    // Проверяем, что запись принадлежит пользователю
    final checkResults = await _dbQuery(
      'SELECT id FROM sleep_records WHERE id = @id AND user_id = @userId',
      substitutionValues: {'id': id, 'userId': userId},
    );

    if (checkResults.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    final results = await _dbQuery(
      'UPDATE sleep_records '
      'SET sleep_date = @sleepDate, bed_time = CAST(@bedTime AS time), '
      'wake_time = CAST(@wakeTime AS time), quality = @quality '
      'WHERE id = @id AND user_id = @userId '
      'RETURNING id, user_id, sleep_date, bed_time, wake_time, quality',
      substitutionValues: {
        'sleepDate': sleepDt,
        'bedTime': (bedTime != null && bedTime.isNotEmpty) ? bedTime : null,
        'wakeTime': (wakeTime != null && wakeTime.isNotEmpty) ? wakeTime : null,
        'quality': quality,
        'id': id,
        'userId': userId,
      },
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    final row = results.first;

    String? bedTimeResult;
    if (row[3] != null) {
      bedTimeResult = row[3] is String ? row[3] : String.fromCharCodes(row[3] as List<int>);
    }

    String? wakeTimeResult;
    if (row[4] != null) {
      wakeTimeResult = row[4] is String ? row[4] : String.fromCharCodes(row[4] as List<int>);
    }

    return Response.json(body: {
      'id': row[0] as String,
      'user_id': row[1] as String,
      'sleep_date': (row[2] as DateTime).toIso8601String().split('T').first,
      'bed_time': bedTimeResult != null && bedTimeResult.isNotEmpty ? bedTimeResult : null,
      'wake_time': wakeTimeResult != null && wakeTimeResult.isNotEmpty ? wakeTimeResult : null,
      'quality': row[5] as int?,
    });
  } catch (e) {
    print('_updateSleepRecord: ошибка: $e');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Удалить запись сна
Future<Response> _deleteSleepRecord(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _dbQuery(
      'DELETE FROM sleep_records WHERE id = @id AND user_id = @userId RETURNING id',
      substitutionValues: {'id': id, 'userId': userId},
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Record not found');
    }

    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== MOOD ENDPOINTS ====================
