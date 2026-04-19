/// Конфигурация API-адресов.
///
/// Для смены адреса используйте скрипт:
///   .\scripts\set-ip.ps1              - автоопределение IP
///   .\scripts\set-ip.ps1 -Emulator    - для Android-эмулятора (10.0.2.2)
///   .\scripts\set-ip.ps1 -Ip 192.168.0.100 - конкретный IP
class ApiConfig {
  /// Базовый URL backend.
  static const String baseUrl = 'http://10.0.2.2:8081';

  /// Freesound API
  /// Получить API ключ: https://freesound.org/help/developer/
  static const String freesoundApiKey = 'LUHnUrXlccZbQTbQsfDSV7uEHHMuka6VjqgnBbW6';
  static const String freesoundBaseUrl = 'https://freesound.org/apiv2';
}
