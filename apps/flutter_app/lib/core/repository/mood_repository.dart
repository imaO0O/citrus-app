import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../screens/models/mood.dart';

/// Хранилище настроений — сохраняет записи в JSON-файл
class MoodRepository {
  static const String _fileName = 'mood_data.json';

  MoodRepository._();

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<_MoodData> _load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return _MoodData.empty();
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return _MoodData.fromJson(json);
    } catch (_) {
      return _MoodData.empty();
    }
  }

  static Future<void> _save(_MoodData data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data.toJson()));
  }

  /// Получить все записи
  static Future<List<MoodLogEntry>> getEntries() async {
    final data = await _load();
    return data.entries
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Добавить запись
  static Future<void> addEntry(MoodLogEntry entry) async {
    final data = await _load();
    data.entries.add(entry);

    if (data.entries.length > 500) {
      data.entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      data.entries.length = 500;
    }

    await _updateStreak(data, entry.timestamp);
    await _save(data);
  }

  /// Получить записи за конкретный день
  static Future<List<MoodLogEntry>> getEntriesForDay(DateTime date) async {
    final entries = await getEntries();
    return entries.where((e) =>
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList();
  }

  /// Получить записи за последние 7 дней
  static Future<List<MoodLogEntry>> getEntriesLastDays(int days) async {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final entries = await getEntries();
    return entries.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  /// Текущая серия дней подряд
  static Future<int> getStreak() async {
    final data = await _load();
    return data.streak;
  }

  /// Процент "хороших" дней (настроение <= 1) за последние 7 дней
  static Future<double> getGoodDaysPercentage() async {
    final entries = await getEntriesLastDays(7);
    if (entries.isEmpty) return 0;

    final uniqueDays = <String>{};
    final goodDays = <String>{};

    for (final entry in entries) {
      final dayKey = '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      uniqueDays.add(dayKey);
      if (entry.moodId <= 1) {
        goodDays.add(dayKey);
      }
    }

    if (uniqueDays.isEmpty) return 0;
    return (goodDays.length / uniqueDays.length) * 100;
  }

  /// Среднее настроение за последние 7 дней
  static Future<double> getAverageMood() async {
    final entries = await getEntriesLastDays(7);
    if (entries.isEmpty) return 0;
    return entries.map((e) => e.moodId).reduce((a, b) => a + b) / entries.length;
  }

  /// Настроение сегодня
  static Future<List<MoodLogEntry>> getTodayEntries() async {
    return getEntriesForDay(DateTime.now());
  }

  /// Последнее записанное настроение
  static Future<MoodLogEntry?> getLastEntry() async {
    final entries = await getEntries();
    return entries.isEmpty ? null : entries.first;
  }

  /// Обновить streak
  static Future<void> _updateStreak(_MoodData data, DateTime entryTime) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = data.streak;

    if (data.lastDate == null) {
      streak = 1;
    } else {
      final lastDay = DateTime(
        data.lastDate!.year,
        data.lastDate!.month,
        data.lastDate!.day,
      );

      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Тот же день
      } else if (diff == 1) {
        streak++;
      } else {
        streak = 1;
      }
    }

    data.streak = streak;
    data.lastDate = entryTime;
  }

  /// Очистить все данные
  static Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

class _MoodData {
  List<MoodLogEntry> entries;
  int streak;
  DateTime? lastDate;

  _MoodData({
    required this.entries,
    required this.streak,
    this.lastDate,
  });

  factory _MoodData.empty() => _MoodData(entries: [], streak: 0);

  Map<String, dynamic> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
    'streak': streak,
    'lastDate': lastDate?.toIso8601String(),
  };

  factory _MoodData.fromJson(Map<String, dynamic> json) => _MoodData(
    entries: (json['entries'] as List<dynamic>)
        .map((e) => MoodLogEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    streak: json['streak'] as int? ?? 0,
    lastDate: json['lastDate'] != null
        ? DateTime.parse(json['lastDate'] as String)
        : null,
  );
}
