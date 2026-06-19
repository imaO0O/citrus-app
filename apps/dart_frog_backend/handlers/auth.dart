part of '../server.dart';

Future<Response> _register(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final name = body['name'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'email and password are required');
    }

    if (password.length < 6) {
      return Response(statusCode: 400, body: 'Password must be at least 6 characters');
    }

    // Проверяем существование пользователя
    final existing = await _dbQuery(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (existing.isNotEmpty) {
      return Response(statusCode: 409, body: 'User already exists');
    }

    final userId = const Uuid().v4();
    final passwordHash = _hashPassword(password);
    final nameSql = name != null && name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';

    await _dbQuery(
      "INSERT INTO users (id, email, password_hash, name, theme_id) VALUES ('$userId', '$email', '$passwordHash', $nameSql, '00000000-0000-0000-0000-000000000001')",
    );

    // Создаем JWT токен
    final token = JWT(
      {'user_id': userId, 'email': email},
      issuer: 'citrus-app',
    ).sign(SecretKey(_jwtSecret));

    return Response.json(
      statusCode: 201,
      body: {
        'id': userId,
        'email': email,
        'name': name,
        'theme_id': '00000000-0000-0000-0000-000000000001',
        'avatar_url': null,
        'phone': null,
        'token': token,
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

Future<Response> _login(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'email and password are required');
    }

    final results = await _dbQuery(
      "SELECT id, email, name, theme_id, password_hash, avatar_url, phone FROM users WHERE email = '$email'",
    );

    if (results.isEmpty) {
      return Response(statusCode: 401, body: 'Invalid credentials');
    }

    final row = results.first;
    final storedHash = row[4] as String;
    final inputHash = _hashPassword(password);

    if (storedHash != inputHash) {
      return Response(statusCode: 401, body: 'Invalid credentials');
    }

    final userId = row[0] as String;
    final token = JWT(
      {'user_id': userId, 'email': email},
      issuer: 'citrus-app',
    ).sign(SecretKey(_jwtSecret));

    return Response.json(body: {
      'id': userId,
      'email': row[1] as String,
      'name': row[2] as String?,
      'theme_id': row[3] as String?,
      'avatar_url': row[5] as String?,
      'phone': row[6] as String?,
      'token': token,
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Запросить сброс пароля — отправить код на email
Future<Response> _forgotPassword(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;

    if (email == null || email.isEmpty) {
      return Response(statusCode: 400, body: 'email is required');
    }

    // Проверяем, существует ли пользователь
    final results = await _dbQuery(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (results.isEmpty) {
      return Response.json(body: {'error': 'Пользователь с таким email не найден'});
    }

    final userId = results.first[0] as String;

    // Инвалидируем старые коды
    await _dbQuery(
      "UPDATE password_reset_tokens SET used = true WHERE user_id = '$userId' AND used = false",
    );

    // Генерируем 6-значный код
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

    // Сохраняем код (действителен 15 минут)
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    final tokenId = const Uuid().v4();

    await _dbQuery(
      "INSERT INTO password_reset_tokens (id, user_id, code, expires_at) VALUES ('$tokenId', '$userId', '$code', '${expiresAt.toIso8601String()}')",
    );

    // Отправляем email
    final sent = await EmailService.sendPasswordResetCode(email, code);
    if (!sent) {
      print('Failed to send reset email to $email, but code is stored');
    }

    return Response.json(body: {'message': 'Если аккаунт с таким email существует, код отправлен'});
  } catch (e, stackTrace) {
    print('ERROR in _forgotPassword: $e');
    print('Stack trace: $stackTrace');
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Сбросить пароль по коду
Future<Response> _resetPassword(RequestContext context) async {
  try {
    final body = await context.request.json();
    final email = body['email'] as String?;
    final code = body['code'] as String?;
    final newPassword = body['new_password'] as String?;

    if (email == null || code == null || newPassword == null) {
      return Response(statusCode: 400, body: 'email, code and new_password are required');
    }

    if (newPassword.length < 6) {
      return Response(statusCode: 400, body: 'Password must be at least 6 characters');
    }

    // Находим пользователя
    final userResults = await _dbQuery(
      "SELECT id FROM users WHERE email = '$email'",
    );

    if (userResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final userId = userResults.first[0] as String;

    // Проверяем код
    final tokenResults = await _dbQuery(
      "SELECT id, expires_at FROM password_reset_tokens WHERE user_id = '$userId' AND code = '$code' AND used = false ORDER BY created_at DESC LIMIT 1",
    );

    if (tokenResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final expiresAt = tokenResults.first[1] as DateTime;
    if (DateTime.now().isAfter(expiresAt)) {
      // Код просрочен
      await _dbQuery(
        "UPDATE password_reset_tokens SET used = true WHERE id = '${tokenResults.first[0]}'",
      );
      return Response(statusCode: 400, body: 'Code has expired');
    }

    // Помечаем код как использованный
    await _dbQuery(
      "UPDATE password_reset_tokens SET used = true WHERE id = '${tokenResults.first[0]}'",
    );

    // Обновляем пароль
    final passwordHash = _hashPassword(newPassword);
    await _dbQuery(
      "UPDATE users SET password_hash = '$passwordHash' WHERE id = '$userId'",
    );

    return Response.json(body: {'message': 'Password has been reset successfully'});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

