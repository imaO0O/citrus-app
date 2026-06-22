part of '../server.dart';

/// Получить список всех тем
Future<Response> _getThemes(RequestContext context) async {
  try {
    final results = await _dbQuery(
      'SELECT id, name, is_dark, primary_color, accent_color FROM themes ORDER BY id',
    );

    final themes = results.map((row) {
      return {
        'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
        'name': row[1] as String,
        'is_dark': row[2] as bool,
        'primary_color': row[3] as String,
        'accent_color': row[4] as String,
      };
    }).toList();

    return Response.json(body: themes);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить тему пользователя
Future<Response> _getUserTheme(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _dbQuery(
      'SELECT theme_id FROM users WHERE id = @userId',
      substitutionValues: {'userId': userId},
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final themeId = result.first[0] as String?;
    return Response.json(body: {'theme_id': themeId});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить тему пользователя
Future<Response> _updateUserTheme(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;
    final body = await context.request.json();
    final themeId = body['theme_id'] as String?;

    if (themeId == null) {
      return Response(statusCode: 400, body: 'theme_id is required');
    }

    await _dbQuery(
      'UPDATE users SET theme_id = @themeId WHERE id = @userId',
      substitutionValues: {'themeId': themeId, 'userId': userId},
    );

    return Response.json(body: {'theme_id': themeId});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Экспорт всех данных пользователя одним JSON (право на переносимость данных)
Future<Response> _exportUserData(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    // row_to_json отдаёт строку таблицы готовым JSON — не зависит от набора колонок.
    // Имя таблицы — это литерал из кода (не пользовательский ввод).
    Future<List<dynamic>> rowsAsJson(String table) async {
      try {
        final result = await _dbQuery(
          'SELECT row_to_json(t)::text FROM $table t WHERE user_id = @userId',
          substitutionValues: {'userId': userId},
        );
        return result.map((r) => jsonDecode(r[0] as String)).toList();
      } catch (_) {
        return []; // таблицы может не быть — пропускаем
      }
    }

    final profile = await _dbQuery(
      'SELECT row_to_json(u)::text FROM '
      '(SELECT id, email, name, theme_id, avatar_url, phone FROM users WHERE id = @userId) u',
      substitutionValues: {'userId': userId},
    );

    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'profile': profile.isNotEmpty ? jsonDecode(profile.first[0] as String) : null,
      'mood_entries': await rowsAsJson('mood_entries'),
      'sleep_records': await rowsAsJson('sleep_records'),
      'diary_entries': await rowsAsJson('diary_entries'),
      'calendar_events': await rowsAsJson('calendar_events'),
      'memory_photos': await rowsAsJson('memory_photos'),
      'test_results': await rowsAsJson('psychological_test_results'),
      'trusted_contacts': await rowsAsJson('trusted_contacts'),
      'chat_messages': await rowsAsJson('chat_messages'),
      'exercises': await rowsAsJson('user_exercises'),
      'casino': await rowsAsJson('casino_users'),
      'articles': await rowsAsJson('articles'),
    };

    return Response.json(body: data);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Удалить аккаунт и все данные пользователя (право на удаление)
Future<Response> _deleteUserAccount(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    // Имена таблиц — литералы из кода, не пользовательский ввод.
    const userTables = [
      'mood_entries', 'sleep_records', 'diary_entries', 'calendar_events',
      'memory_photos', 'psychological_test_results', 'trusted_contacts',
      'chat_messages', 'user_exercises', 'casino_users', 'articles',
      'password_reset_tokens',
    ];

    for (final table in userTables) {
      try {
        await _dbQuery(
          'DELETE FROM $table WHERE user_id = @userId',
          substitutionValues: {'userId': userId},
        );
      } catch (_) {
        // таблицы может не быть — пропускаем
      }
    }

    await _dbQuery(
      'DELETE FROM users WHERE id = @userId',
      substitutionValues: {'userId': userId},
    );

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Получить профиль пользователя
Future<Response> _getUserProfile(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    final result = await _dbQuery(
      'SELECT id, email, name, theme_id, avatar_url, phone FROM users WHERE id = @userId',
      substitutionValues: {'userId': userId},
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] as String,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'avatar_url': row[4] as String?,
      'phone': row[5] as String?,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить профиль пользователя (имя, телефон)
Future<Response> _updateUserProfile(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;
    final body = await context.request.json();

    final name = body['name'] as String?;
    final phone = body['phone'] as String?;

    final cleanName = (name != null && name.isNotEmpty) ? name : null;
    final cleanPhone = (phone != null && phone.isNotEmpty) ? phone : null;

    await _dbQuery(
      'UPDATE users SET name = @name, phone = @phone WHERE id = @userId',
      substitutionValues: {'name': cleanName, 'phone': cleanPhone, 'userId': userId},
    );

    // Возвращаем обновлённый профиль
    final result = await _dbQuery(
      'SELECT id, email, name, theme_id, avatar_url, phone FROM users WHERE id = @userId',
      substitutionValues: {'userId': userId},
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'User not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] as String,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'avatar_url': row[4] as String?,
      'phone': row[5] as String?,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Загрузить аватар пользователя
Future<Response> _uploadUserAvatar(RequestContext context) async {
  final token = _extractToken(context);
  if (token == null) {
    return Response(statusCode: 401, body: 'Unauthorized');
  }

  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final userId = jwt.payload['user_id'] as String;

    // Multipart upload
    final formData = await context.request.formData();
    final file = formData.files['file'];

    if (file == null) {
      return Response(statusCode: 400, body: 'file is required');
    }

    final fileBytes = Uint8List.fromList(await file.readAsBytes());
    final fileName = file.name;
    final mimeType = lookupMimeType(fileName) ?? file.contentType.mimeType;

    // Загружаем в Cloudinary
    final cloudinaryUrl = await _uploadToCloudinary(fileBytes, fileName, mimeType);

    // Обновляем аватар в БД
    await _dbQuery(
      'UPDATE users SET avatar_url = @avatarUrl WHERE id = @userId',
      substitutionValues: {'avatarUrl': cloudinaryUrl, 'userId': userId},
    );

    return Response.json(body: {
      'avatar_url': cloudinaryUrl,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
