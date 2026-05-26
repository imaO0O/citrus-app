import 'package:intl/intl.dart';
import '../core/repository/diary_repository.dart';

/// Сервис для загрузки и форматирования записей дневника для отправки в чат
class DiaryLoaderService {
  final DiaryRepository _diaryRepo;

  DiaryLoaderService({required DiaryRepository diaryRepo}) : _diaryRepo = diaryRepo;

  /// Загрузить все записи дневника за период
  Future<List<DiaryEntry>> loadDiaryEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;

    return await _diaryRepo.getEntries(startDate: start, endDate: end);
  }

  /// Загрузить записи и отформатировать выбранные для отправки в чат
  String formatSelectedEntries(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return 'Нет записей дневника для анализа.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📓 *Записи дневника для анализа*');
    buffer.writeln('');
    buffer.writeln('📅 *Период:* ${DateFormat('dd.MM.yyyy').format(entries.last.entryDate)} — ${DateFormat('dd.MM.yyyy').format(entries.first.entryDate)}');
    buffer.writeln('📝 *Записей:* ${entries.length}');
    buffer.writeln('');

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(entry.entryDate);
      
      buffer.writeln('━━━ Запись ${i + 1} — $dateStr ━━━');
      
      if (entry.moodValue != null) {
        final moodEmojis = ['😄', '🙂', '😐', '😟', '😢', '😞'];
        final moodLabels = ['Отлично', 'Хорошо', 'Нормально', 'Плохо', 'Очень плохо', 'Ужасно'];
        final moodIdx = entry.moodValue!.clamp(0, 5);
        buffer.writeln('${moodEmojis[moodIdx]} Настроение: ${moodLabels[moodIdx]}');
      }
      
      buffer.writeln('📝 Содержание:');
      buffer.writeln(entry.content);
      buffer.writeln('');
    }

    buffer.writeln('');
    buffer.writeln('_Проанализируй эти записи и дай рекомендации по улучшению ментального здоровья._');

    return buffer.toString();
  }
}
