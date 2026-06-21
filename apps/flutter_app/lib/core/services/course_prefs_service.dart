import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Прогресс по курсу: завершённые дни (индексы) и рефлексии.
class CourseProgress {
  final Set<int> doneDays;
  final Map<int, String> reflections;

  CourseProgress(this.doneDays, this.reflections);

  bool isDone(int day) => doneDays.contains(day);

  /// День разблокирован, если это первый день или предыдущий завершён.
  bool isUnlocked(int day) => day == 0 || doneDays.contains(day - 1);
}

/// Локальное хранение прогресса по мини-курсам (без бэкенда).
class CoursePrefsService {
  static const _storage = FlutterSecureStorage();

  String _key(String courseId) => 'course_$courseId';

  Future<CourseProgress> getProgress(String courseId) async {
    final raw = await _storage.read(key: _key(courseId));
    if (raw == null || raw.isEmpty) return CourseProgress(<int>{}, <int, String>{});
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final done = ((m['done'] as List?) ?? const [])
          .map((e) => e is int ? e : int.tryParse('$e') ?? -1)
          .where((e) => e >= 0)
          .toSet();
      final refl = <int, String>{};
      (m['reflections'] as Map?)?.forEach((k, v) {
        final idx = int.tryParse(k.toString());
        if (idx != null) refl[idx] = v.toString();
      });
      return CourseProgress(done, refl);
    } catch (_) {
      return CourseProgress(<int>{}, <int, String>{});
    }
  }

  Future<void> completeDay(String courseId, int day, String reflection) async {
    final p = await getProgress(courseId);
    p.doneDays.add(day);
    if (reflection.trim().isNotEmpty) {
      p.reflections[day] = reflection.trim();
    }
    await _save(courseId, p);
  }

  Future<void> _save(String courseId, CourseProgress p) async {
    await _storage.write(
      key: _key(courseId),
      value: jsonEncode({
        'done': p.doneDays.toList(),
        'reflections': p.reflections.map((k, v) => MapEntry(k.toString(), v)),
      }),
    );
  }
}
