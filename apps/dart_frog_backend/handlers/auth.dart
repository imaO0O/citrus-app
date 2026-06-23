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
      'SELECT id FROM users WHERE email = @email',
      substitutionValues: {'email': email},
    );

    if (existing.isNotEmpty) {
      return Response(statusCode: 409, body: 'User already exists');
    }

    final userId = const Uuid().v4();
    final passwordHash = _hashPassword(password);
    final cleanName = (name != null && name.isNotEmpty) ? name : null;

    await _dbQuery(
      'INSERT INTO users (id, email, password_hash, name, theme_id) '
      "VALUES (@id, @email, @passwordHash, @name, '00000000-0000-0000-0000-000000000001')",
      substitutionValues: {
        'id': userId,
        'email': email,
        'passwordHash': passwordHash,
        'name': cleanName,
      },
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
        'is_admin': email.toLowerCase() == _adminEmail.toLowerCase(),
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

    // Защита от перебора пароля: не больше 10 попыток за 10 минут на email.
    if (!_rateLimitAllowed('login:${email.toLowerCase()}', 10, const Duration(minutes: 10))) {
      return Response(statusCode: 429, body: 'Слишком много попыток входа. Попробуйте позже.');
    }

    final results = await _dbQuery(
      'SELECT id, email, name, theme_id, password_hash, avatar_url, phone FROM users WHERE email = @email',
      substitutionValues: {'email': email},
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
      'is_admin': (row[1] as String).toLowerCase() == _adminEmail.toLowerCase(),
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

    // Защита от спама кодами: не больше 5 запросов за час на email.
    if (!_rateLimitAllowed('forgot:${email.toLowerCase()}', 5, const Duration(minutes: 60))) {
      return Response(statusCode: 429, body: 'Слишком много запросов кода. Попробуйте позже.');
    }

    // Проверяем, существует ли пользователь
    final results = await _dbQuery(
      'SELECT id FROM users WHERE email = @email',
      substitutionValues: {'email': email},
    );

    if (results.isEmpty) {
      return Response.json(body: {'error': 'Пользователь с таким email не найден'});
    }

    final userId = results.first[0] as String;

    // Инвалидируем старые коды
    await _dbQuery(
      'UPDATE password_reset_tokens SET used = true WHERE user_id = @userId AND used = false',
      substitutionValues: {'userId': userId},
    );

    // Генерируем 6-значный код
    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

    // Сохраняем код (действителен 15 минут)
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    final tokenId = const Uuid().v4();

    await _dbQuery(
      'INSERT INTO password_reset_tokens (id, user_id, code, expires_at) '
      'VALUES (@id, @userId, @code, @expiresAt)',
      substitutionValues: {
        'id': tokenId,
        'userId': userId,
        'code': code,
        'expiresAt': expiresAt,
      },
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

    // Защита от перебора 6-значного кода: не больше 8 попыток за 15 минут на email.
    if (!_rateLimitAllowed('reset:${email.toLowerCase()}', 8, const Duration(minutes: 15))) {
      return Response(statusCode: 429, body: 'Слишком много попыток. Попробуйте позже.');
    }

    // Находим пользователя
    final userResults = await _dbQuery(
      'SELECT id FROM users WHERE email = @email',
      substitutionValues: {'email': email},
    );

    if (userResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final userId = userResults.first[0] as String;

    // Проверяем код
    final tokenResults = await _dbQuery(
      'SELECT id, expires_at FROM password_reset_tokens '
      'WHERE user_id = @userId AND code = @code AND used = false '
      'ORDER BY created_at DESC LIMIT 1',
      substitutionValues: {'userId': userId, 'code': code},
    );

    if (tokenResults.isEmpty) {
      return Response(statusCode: 400, body: 'Invalid or expired code');
    }

    final tokenId = tokenResults.first[0] as String;
    final expiresAt = tokenResults.first[1] as DateTime;
    if (DateTime.now().isAfter(expiresAt)) {
      // Код просрочен
      await _dbQuery(
        'UPDATE password_reset_tokens SET used = true WHERE id = @id',
        substitutionValues: {'id': tokenId},
      );
      return Response(statusCode: 400, body: 'Code has expired');
    }

    // Помечаем код как использованный
    await _dbQuery(
      'UPDATE password_reset_tokens SET used = true WHERE id = @id',
      substitutionValues: {'id': tokenId},
    );

    // Обновляем пароль
    final passwordHash = _hashPassword(newPassword);
    await _dbQuery(
      'UPDATE users SET password_hash = @passwordHash WHERE id = @userId',
      substitutionValues: {'passwordHash': passwordHash, 'userId': userId},
    );

    return Response.json(body: {'message': 'Password has been reset successfully'});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
