import 'storage_service.dart';

/// Вариант фокуса (что пользователю важнее всего сейчас).
class FocusOption {
  final String key;
  final String emoji;
  final String label;
  const FocusOption(this.key, this.emoji, this.label);
}

/// Доступные направления — выбираются в онбординге, влияют на рекомендации.
const List<FocusOption> kFocusOptions = [
  FocusOption('anxiety', '😟', 'Меньше тревожиться'),
  FocusOption('mood', '💧', 'Поднять настроение'),
  FocusOption('sleep', '🌙', 'Наладить сон'),
  FocusOption('stress', '📚', 'Учёба и стресс'),
  FocusOption('self_esteem', '💗', 'Повысить самооценку'),
  FocusOption('focus_habits', '🌱', 'Полезные привычки'),
];

/// Хранит выбранные пользователем цели и сопоставляет их с контентом.
class FocusPrefsService {
  static const _focusKey = 'user_focus';
  static const _doneKey = 'personalize_done';

  /// Сопоставление фокуса с id курсов для рекомендаций (по порядку важности).
  static const Map<String, List<String>> focusToCourse = {
    'anxiety': ['anxiety', 'mindfulness'],
    'mood': ['gratitude', 'self_esteem', 'loneliness'],
    'sleep': ['sleep', 'digital'],
    'stress': ['exam_stress', 'burnout', 'mindfulness'],
    'self_esteem': ['self_esteem', 'gratitude'],
    'focus_habits': ['procrastination', 'digital'],
  };

  Future<List<String>> getFocus() async {
    final raw = await StorageService().getString(_focusKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((e) => e.isNotEmpty).toList();
  }

  Future<void> setFocus(List<String> keys) async {
    await StorageService().setString(_focusKey, keys.join(','));
    await StorageService().setString(_doneKey, 'true');
  }

  Future<bool> isDone() async =>
      (await StorageService().getString(_doneKey)) == 'true';

  /// id курсов, рекомендованных по выбранным целям.
  Future<Set<String>> recommendedCourseIds() async {
    final focus = await getFocus();
    final ids = <String>{};
    for (final k in focus) {
      ids.addAll(focusToCourse[k] ?? const []);
    }
    return ids;
  }
}
