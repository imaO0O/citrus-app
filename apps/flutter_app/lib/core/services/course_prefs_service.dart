import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Прогресс по курсу: дата завершения каждого дня и рефлексии.
class CourseProgress {
  final Map<int, DateTime> doneAt;
  final Map<int, String> reflections;

  CourseProgress(this.doneAt, this.reflections);

  Set<int> get doneDays => doneAt.keys.toSet();

  bool isDone(int day) => doneAt.containsKey(day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// День открыт, если это первый день ИЛИ предыдущий завершён в ПРОШЛЫЙ
  /// календарный день (правило «один урок в день»).
  bool isUnlocked(int day) {
    if (day == 0) return true;
    final prev = doneAt[day - 1];
    if (prev == null) return false;
    return !_sameDay(prev, DateTime.now());
  }

  /// Если день заблокирован «до завтра» (предыдущий пройден сегодня) — дата
  /// открытия; иначе null (заблокирован, т.к. предыдущий ещё не пройден).
  DateTime? unlockDate(int day) {
    if (day == 0) return null;
    final prev = doneAt[day - 1];
    if (prev == null) return null;
    if (_sameDay(prev, DateTime.now())) {
      return DateTime(prev.year, prev.month, prev.day).add(const Duration(days: 1));
    }
    return null;
  }
}

/// Локальное хранение прогресса по мини-курсам (без бэкенда).
class CoursePrefsService {
  static const _storage = FlutterSecureStorage();

  String _key(String courseId) => 'course_$courseId';

  Future<CourseProgress> getProgress(String courseId) async {
    final raw = await _storage.read(key: _key(courseId));
    if (raw == null || raw.isEmpty) return CourseProgress(<int, DateTime>{}, <int, String>{});
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final doneAt = <int, DateTime>{};
      final da = m['doneAt'];
      if (da is Map) {
        da.forEach((k, v) {
          final idx = int.tryParse(k.toString());
          final dt = DateTime.tryParse(v.toString());
          if (idx != null && dt != null) doneAt[idx] = dt;
        });
      } else {
        // Старый формат ('done' — список индексов без дат): считаем выполненными
        // давно, чтобы следующий день был открыт.
        for (final e in ((m['done'] as List?) ?? const [])) {
          final idx = e is int ? e : int.tryParse('$e');
          if (idx != null && idx >= 0) doneAt[idx] = DateTime(2000);
        }
      }
      final refl = <int, String>{};
      (m['reflections'] as Map?)?.forEach((k, v) {
        final idx = int.tryParse(k.toString());
        if (idx != null) refl[idx] = v.toString();
      });
      return CourseProgress(doneAt, refl);
    } catch (_) {
      return CourseProgress(<int, DateTime>{}, <int, String>{});
    }
  }

  Future<void> completeDay(String courseId, int day, String reflection) async {
    final p = await getProgress(courseId);
    // Сохраняем исходную дату завершения (повторное сохранение рефлексии её не меняет).
    p.doneAt.putIfAbsent(day, () => DateTime.now());
    if (reflection.trim().isNotEmpty) {
      p.reflections[day] = reflection.trim();
    }
    await _save(courseId, p);
  }

  Future<void> resetCourse(String courseId) async {
    await _storage.delete(key: _key(courseId));
  }

  Future<void> _save(String courseId, CourseProgress p) async {
    await _storage.write(
      key: _key(courseId),
      value: jsonEncode({
        'doneAt': p.doneAt.map((k, v) => MapEntry(k.toString(), v.toIso8601String())),
        'reflections': p.reflections.map((k, v) => MapEntry(k.toString(), v)),
      }),
    );
  }
}
