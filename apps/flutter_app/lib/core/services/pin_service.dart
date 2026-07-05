import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Локальная блокировка приложения PIN-кодом. PIN хранится в защищённом
/// (зашифрованном) хранилище устройства.
class PinService {
  static const _storage = FlutterSecureStorage();
  static const _kEnabled = 'pin_enabled';
  static const _kPin = 'app_pin';

  Future<bool> isEnabled() async => (await _storage.read(key: _kEnabled)) == 'true';

  Future<void> setPin(String pin) async {
    await _storage.write(key: _kPin, value: pin);
    await _storage.write(key: _kEnabled, value: 'true');
  }

  Future<bool> verify(String pin) async => (await _storage.read(key: _kPin)) == pin;

  Future<void> disable() async {
    await _storage.delete(key: _kPin);
    await _storage.write(key: _kEnabled, value: 'false');
  }
}
