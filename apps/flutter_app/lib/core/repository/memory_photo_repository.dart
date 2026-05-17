import 'dart:io';
import 'package:intl/intl.dart';
import '../../models/memory_photo.dart';
import '../../core/api/memory_photo_api_service.dart';

class MemoryPhotoRepository {
  MemoryPhotoApiService _apiService;
  String _userId;
  String? _token;

  MemoryPhotoRepository({
    required String userId,
    String? token,
    MemoryPhotoApiService? apiService,
  })  : _userId = userId,
        _token = token,
        _apiService = apiService ?? MemoryPhotoApiService(token: token);

  void setUserId(String userId, {String? token}) {
    _userId = userId;
    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService = MemoryPhotoApiService(token: token);
    }
  }

  String get userId => _userId;

  /// Получить все фото
  Future<List<MemoryPhoto>> getPhotos() async {
    final data = await _apiService.getPhotos();
    return data.map((e) => MemoryPhoto.fromJson(e)).toList();
  }

  /// Загрузить фото с устройства
  Future<MemoryPhoto> uploadPhoto({
    required File imageFile,
    String? caption,
    DateTime? photoDate,
  }) async {
    final data = await _apiService.uploadPhoto(
      imageFile: imageFile,
      caption: caption,
      photoDate: photoDate != null ? DateFormat('yyyy-MM-dd').format(photoDate) : null,
    );
    return MemoryPhoto.fromJson(data);
  }

  /// Удалить фото
  Future<void> deletePhoto(String id) async {
    await _apiService.deletePhoto(id);
  }

  /// Переключить избранное
  Future<bool> toggleFavorite(String id) async {
    return await _apiService.toggleFavorite(id);
  }
}
