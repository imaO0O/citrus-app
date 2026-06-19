part of '../server.dart';

/// Загрузка изображения в Cloudinary через Unsigned upload preset
Future<String> _uploadToCloudinary(Uint8List fileBytes, String fileName, String mimeType) async {
  final publicId = 'citrus_${DateTime.now().millisecondsSinceEpoch}';

  final request = http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl));
  request.files.add(
    await http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: http.MediaType.parse(mimeType),
    ),
  );
  request.fields['upload_preset'] = 'citrus_unsigned';
  request.fields['public_id'] = publicId;

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  print('Cloudinary upload response: ${response.statusCode} $responseBody');

  if (response.statusCode != 200) {
    throw Exception('Cloudinary upload failed: ${response.statusCode} $responseBody');
  }

  final jsonData = json.decode(responseBody);
  return jsonData['secure_url'] as String;
}

/// Удаление изображения из Cloudinary
Future<void> _deleteFromCloudinary(String imageUrl) async {
  try {
    // URL формат: https://res.cloudinary.com/dgeoniumv/image/upload/v1234/citrus_xxx.jpg
    final uri = Uri.parse(imageUrl);
    final pathParts = uri.pathSegments;

    final uploadIndex = pathParts.indexOf('upload');
    if (uploadIndex == -1 || uploadIndex >= pathParts.length - 1) {
      print('Cloudinary delete: cannot parse URL: $imageUrl');
      return;
    }

    var publicId = pathParts.sublist(uploadIndex + 1).join('/');
    if (publicId.startsWith('v') && publicId.contains('/')) {
      publicId = publicId.substring(publicId.indexOf('/') + 1);
    }
    final dotIndex = publicId.lastIndexOf('.');
    if (dotIndex > 0) {
      publicId = publicId.substring(0, dotIndex);
    }

    print('Cloudinary delete: public_id=$publicId');

    // Signed delete — подпись обязательна
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final paramsToSign = 'public_id=$publicId&timestamp=$timestamp';
    final signature = sha1.convert(utf8.encode('$paramsToSign$_cloudinaryApiSecret')).toString();

    final response = await http.post(
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/destroy'),
      body: {
        'public_id': publicId,
        'api_key': _cloudinaryApiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    if (response.statusCode != 200) {
      print('Cloudinary delete failed: ${response.statusCode} ${response.body}');
    } else {
      print('Cloudinary delete success: ${response.body}');
    }
  } catch (e) {
    print('Error deleting from Cloudinary: $e');
  }
}

/// Получить все доверенные контакты пользователя
Future<Response> _getTrustedContacts(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _dbQuery(
      "SELECT id, name, phone, created_at FROM trusted_contacts WHERE user_id = '$userId' ORDER BY created_at DESC",
    );

    final records = results.map((row) => {
          'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
          'name': row[1],
          'phone': row[2],
          'created_at': row[3]?.toString(),
        }).toList();

    return Response.json(body: records);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

// ==================== Photos / Memory endpoints ====================

/// GET /photos — получить все фото пользователя
Future<Response> _getPhotos(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _dbQuery(
      "SELECT id, user_id, image_url, caption, photo_date::text, is_favorite, created_at::text "
      "FROM memory_photos "
      "WHERE user_id = '$userId' "
      "ORDER BY created_at DESC",
    );

    final photos = results.map((row) => {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'user_id': row[1] is String ? row[1] : Uuid.unparse(row[1] as Uint8List),
      'image_url': row[2],
      'caption': row[3],
      'photo_date': row[4],
      'is_favorite': row[5] == true,
      'created_at': row[6],
    }).toList();

    return Response.json(body: photos);
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Создать доверенный контакт
Future<Response> _createTrustedContact(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final name = body['name'] as String? ?? '';
  final phone = body['phone'] as String?;

  if (phone == null || phone.isEmpty) {
    return Response(statusCode: 400, body: 'phone is required');
  }

  try {
    final contactId = const Uuid().v4();
    final nameSql = name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';

    await _dbQuery(
      "INSERT INTO trusted_contacts (id, user_id, name, phone) VALUES ('$contactId', '$userId', $nameSql, '${phone.replaceAll("'", "''")}')",
    );

    return Response.json(
      statusCode: 201,
      body: {'id': contactId, 'name': name, 'phone': phone},
    );
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}
/// POST /photos — загрузить фото (multipart) -> Cloudinary -> БД
Future<Response> _createPhoto(RequestContext context, _AuthContext auth) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final contentType = context.request.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      // Альтернатива: JSON с URL
      final body = await context.request.json();
      final imageUrl = body['image_url'] as String?;
      final caption = body['caption'] as String?;
      final photoDate = body['photo_date'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        return Response(statusCode: 400, body: 'image_url is required');
      }

      final photoId = const Uuid().v4();
      final photoDateSql = photoDate != null ? "'$photoDate'" : 'NOW()';
      final captionSql = caption != null ? "'${caption.replaceAll("'", "''")}'" : 'NULL';

      await _dbQuery(
        "INSERT INTO memory_photos (id, user_id, image_url, caption, photo_date) "
        "VALUES ('$photoId', '$userId', '$imageUrl', $captionSql, $photoDateSql)",
      );

      return Response.json(statusCode: 201, body: {
        'id': photoId,
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'photo_date': photoDate,
        'is_favorite': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Multipart upload
    final formData = await context.request.formData();
    final file = formData.files['file'];
    final captionField = formData.fields['caption'];
    final photoDateField = formData.fields['photo_date'];

    if (file == null) {
      return Response(statusCode: 400, body: 'file is required');
    }

    final fileBytes = Uint8List.fromList(await file.readAsBytes());
    final fileName = file.name;

    // Определяем MIME-тип
    final mimeType = lookupMimeType(fileName) ?? file.contentType.mimeType;

    // Загружаем в Cloudinary
    final cloudinaryUrl = await _uploadToCloudinary(fileBytes, fileName, mimeType);

    // Сохраняем в БД
    final photoId = const Uuid().v4();
    final photoDate = photoDateField ?? DateTime.now().toIso8601String().split('T').first;
    final caption = captionField;
    final captionSql = caption != null ? "'${caption.replaceAll("'", "''")}'" : 'NULL';

    await _dbQuery(
      "INSERT INTO memory_photos (id, user_id, image_url, caption, photo_date) "
      "VALUES ('$photoId', '$userId', '$cloudinaryUrl', $captionSql, '$photoDate')",
    );

    return Response.json(statusCode: 201, body: {
      'id': photoId,
      'user_id': userId,
      'image_url': cloudinaryUrl,
      'caption': caption,
      'photo_date': photoDate,
      'is_favorite': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Обновить доверенный контакт
Future<Response> _updateTrustedContact(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  final body = await context.request.json();
  final name = body['name'] as String?;
  final phone = body['phone'] as String?;

  if (phone == null || phone.isEmpty) {
    return Response(statusCode: 400, body: 'phone is required');
  }

  try {
    final nameSql = name != null && name.isNotEmpty ? "'${name.replaceAll("'", "''")}'" : 'NULL';
    final phoneSql = phone.replaceAll("'", "''");

    final result = await _dbQuery(
      "UPDATE trusted_contacts SET name = $nameSql, phone = '$phoneSql' WHERE id = '$id' AND user_id = '$userId' RETURNING id, name, phone",
    );

    if (result.isEmpty) {
      return Response(statusCode: 404, body: 'Contact not found');
    }

    final row = result.first;
    return Response.json(body: {
      'id': row[0] is String ? row[0] : Uuid.unparse(row[0] as Uint8List),
      'name': row[1],
      'phone': row[2],
    });
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// PATCH /photos/{id}/favorite — переключить избранное
Future<Response> _togglePhotoFavorite(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final results = await _dbQuery(
      "SELECT is_favorite FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (results.isEmpty) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    final currentFavorite = results.first[0] == true;
    final newFavorite = !currentFavorite;

    await _dbQuery(
      "UPDATE memory_photos SET is_favorite = $newFavorite WHERE id = '$id' AND user_id = '$userId'",
    );

    return Response.json(body: {'is_favorite': newFavorite});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// Удалить доверенный контакт
Future<Response> _deleteTrustedContact(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    final result = await _dbQuery(
      "DELETE FROM trusted_contacts WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Contact not found');
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

/// DELETE /photos/{id} — удалить фото
Future<Response> _deletePhoto(RequestContext context, _AuthContext auth, String id) async {
  final userId = auth.userId;
  if (userId == null) return Response(statusCode: 401, body: 'Unauthorized');

  try {
    // Получаем URL фото для удаления из Cloudinary
    final photoResults = await _dbQuery(
      "SELECT image_url FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (photoResults.isEmpty) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    final imageUrl = photoResults.first[0] as String;

    // Удаляем из БД
    final result = await _dbQuery(
      "DELETE FROM memory_photos WHERE id = '$id' AND user_id = '$userId'",
    );

    if (result.affectedRowCount == 0) {
      return Response(statusCode: 404, body: 'Photo not found');
    }

    // Удаляем из Cloudinary
    try {
      await _deleteFromCloudinary(imageUrl);
    } catch (_) {
      // Игнорируем ошибки удаления из Cloudinary
    }

    return Response.json(body: {'success': true});
  } catch (e) {
    return Response(statusCode: 500, body: 'Error: $e');
  }
}

