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

  /// Сопоставление фокуса с id курса для рекомендаций.
  static const Map<String, String> focusToCourse = {
    'self_esteem': 'self_esteem',
    'stress': 'exam_stress',
    'anxiety': 'mindfulness',
    'mood': 'self_esteem',
    'focus_habits': 'mindfulness',
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
    return focus.map((k) => focusToCourse[k]).whereType<String>().toSet();
  }
}
