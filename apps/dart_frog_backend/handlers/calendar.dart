part of '../server.dart';

Future<Response> _getEvents(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;

  print('_getEvents: запрос для userId=$userId');

  if (userId == null) {
    print('_getEvents: userId is null, возвращаем 401');
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final results = await _dbQuery(
      "SELECT id, user_id, title, description, event_date, "
      "start_time::text as start_time, "
      "end_time::text as end_time, "
      "notification_enabled, recurrence "
      "FROM calendar_events "
      "WHERE user_id = '$userId' "
      "ORDER BY event_date DESC, start_time",
    );

    print('_getEvents: найдено ${results.length} событий');

    final events = results.map((row) {
      // UUID из PostgreSQL возвращается как байты - нужно конвертировать
      final id = row[0];
      final userId = row[1];
      final title = row[2];
      final description = row[3];
      final eventDate = row[4];
      final startTime = row[5];
      final endTime = row[6];
      final notificationEnabled = row[7];
      final recurrence = row[8];

      // Преобразуем startTime и endTime в строку
      String? startTimeStr;
      if (startTime != null) {
        startTimeStr = startTime is String ? startTime : startTime.toString();
      }
      
      String? endTimeStr;
      if (endTime != null) {
        endTimeStr = endTime is String ? endTime : endTime.toString();
      }

      return {
        'id': id is String ? id : Uuid.unparse(id as Uint8List),
        'user_id': userId is String ? userId : Uuid.unparse(userId as Uint8List),
        'title': title is String ? title : '',
        'description': description is String ? description : null,
        'event_date': (eventDate as DateTime).toIso8601String(),
        'start_time': startTimeStr,
        'end_time': endTimeStr,
        'notification_enabled': notificationEnabled as bool,
        'recurrence': recurrence is String ? recurrence : 'none',
      };
    }).toList();

    return Response.json(body: events);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createEvent(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  final body = await context.request.json();
  
  final title = body['title'] as String?;
  final eventDate = body['event_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (title == null || eventDate == null) {
    return Response(statusCode: 400, body: 'title and event_date are required');
  }

  try {
    final eventId = const Uuid().v4();
    final description = body['description'] as String? ?? '';
    final startTime = body['start_time'] as String?;
    final endTime = body['end_time'] as String?;
    final notificationEnabled = body['notification_enabled'] as bool? ?? true;
    final rawRecurrence = body['recurrence'] as String? ?? 'none';
    final recurrence = const ['none', 'daily', 'weekly', 'monthly'].contains(rawRecurrence) ? rawRecurrence : 'none';

    final startTimeSql = startTime != null ? "'$startTime'" : 'NULL';
    final endTimeSql = endTime != null ? "'$endTime'" : 'NULL';
    final descriptionSql = description.isNotEmpty ? "'${description.replaceAll("'", "''")}'" : 'NULL';

    await _dbQuery(
      "INSERT INTO calendar_events (id, user_id, title, description, event_date, start_time, end_time, notification_enabled, recurrence) "
      "VALUES ('$eventId', '$userId', '${title.replaceAll("'", "''")}', $descriptionSql, '$eventDate', $startTimeSql, $endTimeSql, $notificationEnabled, '$recurrence')",
    );

    return Response.json(
      statusCode: 201,
      body: {
        'id': eventId,
        'user_id': userId,
        'title': title,
        'description': description,
        'event_date': eventDate,
        'start_time': startTime,
        'end_time': endTime,
        'notification_enabled': notificationEnabled,
        'recurrence': recurrence,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateEvent(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  final body = await context.request.json();

  final title = body['title'] as String?;
  final eventDate = body['event_date'] as String?;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  if (title == null || eventDate == null) {
    return Response(statusCode: 400, body: 'title and event_date are required');
  }

  try {
    final description = body['description'] as String? ?? '';
    final startTime = body['start_time'] as String?;
    final endTime = body['end_time'] as String?;
    final notificationEnabled = body['notification_enabled'] as bool? ?? true;
    final rawRecurrence = body['recurrence'] as String? ?? 'none';
    final recurrence = const ['none', 'daily', 'weekly', 'monthly'].contains(rawRecurrence) ? rawRecurrence : 'none';

    final startTimeSql = startTime != null ? "'$startTime'" : 'NULL';
    final endTimeSql = endTime != null ? "'$endTime'" : 'NULL';
    final descriptionSql = description.isNotEmpty ? "'${description.replaceAll("'", "''")}'" : 'NULL';

    // Проверяем, что событие принадлежит пользователю
    final checkResults = await _dbQuery(
      "SELECT id FROM calendar_events WHERE id = '$id' AND user_id = '$userId'",
    );

    if (checkResults.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    final results = await _dbQuery(
      "UPDATE calendar_events "
      "SET title = '${title.replaceAll("'", "''")}', description = $descriptionSql, event_date = '$eventDate', "
      "start_time = $startTimeSql, end_time = $endTimeSql, notification_enabled = $notificationEnabled, recurrence = '$recurrence' "
      "WHERE id = '$id' AND user_id = '$userId' "
      "RETURNING id, user_id, title, description, event_date, start_time, end_time, notification_enabled, recurrence",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    final row = results.first;
    return Response.json(body: {
      'id': row[0] as String,
      'user_id': row[1] as String,
      'title': row[2] as String,
      'description': row[3] as String?,
      'event_date': (row[4] as DateTime).toIso8601String(),
      'start_time': row[5] as String?,
      'end_time': row[6] as String?,
      'notification_enabled': row[7] as bool,
      'recurrence': row[8] as String? ?? 'none',
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteEvent(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;

  if (userId == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    // Проверяем и удаляем только свои события
    final results = await _dbQuery(
      "DELETE FROM calendar_events WHERE id = '$id' AND user_id = '$userId' RETURNING id",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Event not found');
    }

    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

