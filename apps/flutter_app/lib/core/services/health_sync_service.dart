import 'package:health/health.dart';

import '../../models/sleep_record.dart';

/// Импорт сна из системного хаба здоровья: Health Connect на Android,
/// HealthKit на iOS. Часы и фитнес-браслеты (Samsung Health, Mi Fitness/Zepp,
/// Garmin, Huawei Health и т.д.) записывают сон туда, поэтому приложению
/// не нужно знать протокол конкретного устройства.
///
/// На web недоступно — вызывающий код должен проверять kIsWeb.
class HealthSyncService {
  final Health _health = Health();

  static const List<HealthDataType> _types = [HealthDataType.SLEEP_SESSION];
  static const List<HealthDataAccess> _access = [HealthDataAccess.READ];

  /// Запросить у системы доступ на чтение сна.
  /// Возвращает true, если доступ выдан.
  Future<bool> requestPermission() async {
    await _health.configure();
    final has = await _health.hasPermissions(_types, permissions: _access);
    if (has == true) return true;
    return await _health.requestAuthorization(_types, permissions: _access);
  }

  /// Прочитать сессии сна за период и преобразовать в записи приложения.
  ///
  /// Если за одну дату пробуждения несколько сессий (дневной сон, дробный сон),
  /// берётся самая длинная. Возвращает черновики записей: id локальный,
  /// userId подставит сервер по токену.
  Future<List<SleepRecord>> fetchSleepRecords({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: _types,
      startTime: from,
      endTime: to,
    );

    // Самая длинная сессия на каждую дату пробуждения
    final byWakeDate = <String, HealthDataPoint>{};
    for (final p in points) {
      final key = _dateKey(p.dateTo);
      final existing = byWakeDate[key];
      if (existing == null ||
          p.dateTo.difference(p.dateFrom) >
              existing.dateTo.difference(existing.dateFrom)) {
        byWakeDate[key] = p;
      }
    }

    return byWakeDate.values.map((p) {
      return SleepRecord(
        id: 'watch_${p.dateTo.millisecondsSinceEpoch}',
        userId: 'unknown', // сервер берёт пользователя из токена
        sleepDate: DateTime(p.dateTo.year, p.dateTo.month, p.dateTo.day),
        bedTime: _hhmmss(p.dateFrom),
        wakeTime: _hhmmss(p.dateTo),
        quality: null, // часы дают фазы, а не оценку 1–5 — оставляем пустым
      );
    }).toList();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _hhmmss(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
}
