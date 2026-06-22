part of '../server.dart';

/// Приводит вход тегов к List<String> для параметра text[].
List<String> _diaryTags(dynamic tags) =>
    tags is List ? tags.map((t) => t.toString()).toList() : <String>[];

Future<Response> _getDiaryEntries(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final query = context.request.uri.queryParameters;
    final startDate = query['start_date'];
    final endDate = query['end_date'];
    final search = query['search'];

    final sv = <String, dynamic>{'userId': userId};
    var whereClause = 'WHERE user_id = @userId';
    final startDt = startDate != null ? DateTime.tryParse(startDate) : null;
    final endDt = endDate != null ? DateTime.tryParse(endDate) : null;
    if (startDt != null) {
      whereClause += ' AND entry_date >= @startDate';
      sv['startDate'] = startDt;
    }
    if (endDt != null) {
      whereClause += ' AND entry_date <= @endDate';
      sv['endDate'] = endDt;
    }
    if (search != null && search.isNotEmpty) {
      whereClause += ' AND content ILIKE @search';
      sv['search'] = '%$search%';
    }

    final results = await _dbQuery(
      'SELECT id, user_id, content, mood_value, entry_date::text, created_at::text, tags '
      'FROM diary_entries $whereClause ORDER BY entry_date DESC, created_at DESC',
      substitutionValues: sv,
    );

    final entries = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'content': row[2] as String?,
      'mood_value': row[3] as int?,
      'entry_date': row[4],
      'created_at': row[5],
      'tags': row[6] is List ? row[6] : <String>[],
      'title': (row[2] as String?)?.substring(0, row[2].toString().length > 50 ? 50 : null) ?? 'Без заголовка',
    }).toList();

    return Response.json(body: entries);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _createDiaryEntry(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final content = body['content'] as String?;
    final moodValue = body['mood_value'] as int?;
    final entryDate = body['entry_date'] as String?;
    final tags = body['tags'];

    if (content == null || content.isEmpty) {
      return Response(statusCode: 400, body: 'content is required');
    }

    final recordId = const Uuid().v4();
    final dateStr = entryDate ?? DateTime.now().toIso8601String();
    final dateVal = DateTime.tryParse(dateStr) ?? DateTime.now();

    await _dbQuery(
      'INSERT INTO diary_entries (id, user_id, content, mood_value, entry_date, tags) '
      'VALUES (@id, @userId, @content, @mood, @entryDate, @tags)',
      substitutionValues: {
        'id': recordId,
        'userId': userId,
        'content': content,
        'mood': moodValue,
        'entryDate': dateVal,
        'tags': _diaryTags(tags),
      },
    );

    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'user_id': userId,
      'content': content,
      'mood_value': moodValue,
      'entry_date': dateStr,
      'tags': tags is List ? tags : <String>[],
    });
  } catch (e, stackTrace) {
    print('diary create error: $e');
    print('stackTrace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _updateDiaryEntry(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final body = await context.request.json();
    final content = body['content'] as String?;
    final moodValue = body['mood_value'] as int?;
    final tags = body['tags'];

    if (content == null) {
      return Response(statusCode: 400, body: 'content is required');
    }

    await _dbQuery(
      'UPDATE diary_entries SET content = @content, mood_value = @mood, tags = @tags '
      'WHERE id = @id AND user_id = @userId',
      substitutionValues: {
        'content': content,
        'mood': moodValue,
        'tags': _diaryTags(tags),
        'id': id,
        'userId': userId,
      },
    );

    final results = await _dbQuery(
      'SELECT id, user_id, content, mood_value, entry_date::text as entry_date, created_at::text as created_at, tags '
      'FROM diary_entries WHERE id = @id AND user_id = @userId',
      substitutionValues: {'id': id, 'userId': userId},
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Entry not found');
    }

    final row = results.first;
    return Response.json(body: {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'content': row[2] as String,
      'mood_value': row[3] as int?,
      'entry_date': row[4] as String?,
      'created_at': row[5] as String?,
      'tags': row[6] is List ? row[6] : <String>[],
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteDiaryEntry(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    await _dbQuery(
      'DELETE FROM diary_entries WHERE id = @id AND user_id = @userId',
      substitutionValues: {'id': id, 'userId': userId},
    );
    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
