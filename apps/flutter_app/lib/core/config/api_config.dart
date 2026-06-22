/// Конфигурация API-адресов.
///
/// Для смены адреса используйте скрипт:
///   .\scripts\set-ip.ps1              - автоопределение IP
///   .\scripts\set-ip.ps1 -Emulator    - для Android-эмулятора (10.0.2.2)
///   .\scripts\set-ip.ps1 -Ip 192.168.0.100 - конкретный IP
class ApiConfig {
  /// Базовый URL backend.
  ///
  /// По умолчанию — прод на Replit. Для локальной разработки переопределяется
  /// без правки кода:
  ///   flutter run --dart-define=API_URL=http://10.0.2.2:8081   (Android-эмулятор)
  ///   flutter run --dart-define=API_URL=http://localhost:8081   (web/десктоп)
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://citrus-app--sahsashishkov.replit.app',
  );

  /// Freesound API
  /// Получить API ключ: https://freesound.org/help/developer/
  static const String freesoundApiKey = 'LUHnUrXlccZbQTbQsfDSV7uEHHMuka6VjqgnBbW6';
  static const String freesoundBaseUrl = 'https://freesound.org/apiv2';
}
