part of '../server.dart';

Future<Response> _getDiaryEntries(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final query = context.request.uri.queryParameters;
    final startDate = query['start_date'];
    final endDate = query['end_date'];
    final search = query['search'];

    String whereClause = "WHERE user_id = '$userId'";
    if (startDate != null) whereClause += " AND entry_date >= '$startDate'";
    if (endDate != null) whereClause += " AND entry_date <= '$endDate'";
    if (search != null && search.isNotEmpty) {
      final escapedSearch = search.replaceAll("'", "''");
      whereClause += " AND content ILIKE '%$escapedSearch%'";
    }

    final results = await _dbQuery(
      "SELECT id, user_id, content, mood_value, entry_date::text, created_at::text "
      "FROM diary_entries $whereClause ORDER BY entry_date DESC, created_at DESC",
    );
    print('DB entry_date values: ${results.map((r) => r[4]).toList()}');

    final entries = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'content': row[2] as String?,
      'mood_value': row[3] as int?,
      'entry_date': row[4],
      'created_at': row[5],
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

    if (content == null || content.isEmpty) {
      return Response(statusCode: 400, body: 'content is required');
    }

    final recordId = const Uuid().v4();
    print('Backend received entryDate: $entryDate');
    final dateStr = entryDate != null ? entryDate : DateTime.now().toIso8601String();
    print('Backend using dateStr: $dateStr');
    final dateSql = "'$dateStr'";
    final contentSql = "'${content.replaceAll("'", "''")}'";
    final moodSql = moodValue != null ? moodValue.toString() : 'NULL';

    await _dbQuery(
      "INSERT INTO diary_entries (id, user_id, content, mood_value, entry_date) "
      "VALUES ('$recordId', '$userId', $contentSql, $moodSql, $dateSql)",
    );

    final returnedDate = dateStr;
    return Response.json(statusCode: 201, body: {
      'id': recordId,
      'user_id': userId,
      'content': content,
      'mood_value': moodValue,
      'entry_date': returnedDate,
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

    if (content == null) {
      return Response(statusCode: 400, body: 'content is required');
    }

    final contentSql = "'${content.replaceAll("'", "''")}'";
    final moodSql = moodValue != null ? moodValue.toString() : 'NULL';

    await _dbQuery(
      "UPDATE diary_entries SET content = $contentSql, mood_value = $moodSql "
      "WHERE id = '$id' AND user_id = '$userId'",
    );

    final results = await _dbQuery(
      "SELECT id, user_id, content, mood_value, entry_date::text as entry_date, created_at::text as created_at "
      "FROM diary_entries WHERE id = '$id' AND user_id = '$userId'",
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
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _deleteDiaryEntry(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    await _dbQuery("DELETE FROM diary_entries WHERE id = '$id' AND user_id = '$userId'");
    return Response(statusCode: 204);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

