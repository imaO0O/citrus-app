import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Простой сервис хранения
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: false),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> setString(String key, String value) async {
    try { await _storage.write(key: key, value: value); } catch (_) {}
  }

  Future<String?> getString(String key) async {
    try { return await _storage.read(key: key); } catch (_) { return null; }
  }

  Future<void> remove(String key) async {
    try { await _storage.delete(key: key); } catch (_) {}
  }

  Future<void> clear() async {
    try { await _storage.deleteAll(); } catch (_) {}
  }
}
