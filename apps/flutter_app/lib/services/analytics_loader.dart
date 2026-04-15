import 'package:intl/intl.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/sleep_repository.dart';
import '../models/sleep_record.dart';
import '../models/analytics_report.dart';

/// Сервис для сбора и форматирования аналитики приложения для отправки в чат
class AnalyticsLoaderService {
  final MoodRepository _moodRepo;
  final SleepRepository? _sleepRepo;

  AnalyticsLoaderService({
    required MoodRepository moodRepo,
    SleepRepository? sleepRepo,
  })  : _moodRepo = moodRepo,
        _sleepRepo = sleepRepo;

  /// Загрузить аналитику и отформатировать в текст для чата
  Future<String> loadAndFormatAnalytics({
    required String token,
    required String userId,
    DateTime? startDate,
  }) async {
    // Настраиваем репозитории
    _moodRepo.setUserId(userId, token: token.isNotEmpty ? token : null);
    _sleepRepo?.setUserId(userId, token: token.isNotEmpty ? token : null);

    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));

    // Загружаем данные
    final moodRecords = await _moodRepo.getRecords(startDate: start, endDate: now);
    final streak = await _moodRepo.getStreak();
    final goodDaysPercent = await _moodRepo.getGoodDaysPercentage();
    final averageMood = await _moodRepo.getAverageMood();
    final moodByDay = await _moodRepo.getAverageMoodByDay(startDate: start, endDate: now);

    // Загружаем данные о сне
    List<SleepRecord> sleepRecords = [];
    double avgSleepHours = 0;
    double avgSleepQuality = 0;
    if (_sleepRepo != null) {
      sleepRecords = await _sleepRepo!.getSleepRecords(startDate: start, endDate: now);
      if (sleepRecords.isNotEmpty) {
        final totalHours = sleepRecords.fold<double>(0, (sum, r) {
          if (r.bedTime != null && r.wakeTime != null) {
            final bed = _parseTime(r.bedTime!);
            final wake = _parseTime(r.wakeTime!);
            if (bed != null && wake != null) {
              double hours = wake - bed;
              if (hours < 0) hours += 24;
              return sum + hours;
            }
          }
          return sum;
        });
        avgSleepHours = totalHours / sleepRecords.length;
        avgSleepQuality = sleepRecords.fold<double>(0, (sum, r) => sum + (r.quality ?? 0)) / sleepRecords.length;
      }
    }

    // Считаем статистику
    final moodCounts = <int, int>{};
    for (final record in moodRecords) {
      moodCounts[record.moodId] = (moodCounts[record.moodId] ?? 0) + 1;
    }

    final totalMoods = moodRecords.length;
    final periodDays = now.difference(start).inDays + 1;

    // Формируем текстовый отчёт
    final buffer = StringBuffer();
    buffer.writeln('📊 *Аналитика за последние ${periodDays} дней*');
    buffer.writeln('');
    buffer.writeln('📅 *Период:* ${DateFormat('dd.MM.yyyy').format(start)} — ${DateFormat('dd.MM.yyyy').format(now)}');
    buffer.writeln('');

    // Основные метрики
    buffer.writeln('🎯 *Основные метрики:*');
    buffer.writeln('  • Записей настроения: $totalMoods');
    buffer.writeln('  • Среднее настроение: ${averageMood.toStringAsFixed(1)}/5');
    buffer.writeln('  • Хороших дней: ${goodDaysPercent.toStringAsFixed(0)}%');
    buffer.writeln('  • Серия подряд дней: $streak');
    
    // Добавляем данные о сне
    if (sleepRecords.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('😴 *Данные о сне:*');
      buffer.writeln('  • Записей сна: ${sleepRecords.length}');
      buffer.writeln('  • Среднее время сна: ${avgSleepHours.toStringAsFixed(1)} ч');
      buffer.writeln('  • Среднее качество: ${avgSleepQuality.toStringAsFixed(1)}/5');
      
      // Оценка качества сна
      if (avgSleepHours >= 7 && avgSleepHours <= 9 && avgSleepQuality >= 4) {
        buffer.writeln('  ✨ Отличный режим сна!');
      } else if (avgSleepHours < 6) {
        buffer.writeln('  ⚠️ Недостаточно сна. Рекомендуется 7-9 часов.');
      } else if (avgSleepQuality < 3) {
        buffer.writeln('  💡 Качество сна можно улучшить. Попробуйте ритуал перед сном.');
      }
    }
    buffer.writeln('');

    // Распределение настроения
    if (totalMoods > 0) {
      buffer.writeln('😊 *Распределение настроения:*');
      final moodEmojis = ['😄', '🙂', '😐', '😟', '😢', '😭'];
      final moodLabels = ['Отлично', 'Хорошо', 'Нормально', 'Плохо', 'Очень плохо', 'Ужасно'];
      for (int i = 0; i <= 5; i++) {
        final count = moodCounts[i] ?? 0;
        if (count > 0) {
          final percent = (count / totalMoods * 100).toStringAsFixed(0);
          buffer.writeln('  ${moodEmojis[i]} $moodLabels[i]: $count ($percent%)');
        }
      }
      buffer.writeln('');
    }

    // Тренд по дням (последние 7 дней)
    if (moodByDay.isNotEmpty) {
      final sortedDays = moodByDay.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
      final last7Days = sortedDays.take(7).toList().reversed;

      buffer.writeln('📈 *Тренд (последние ${last7Days.length} дней):*');
      for (final entry in last7Days) {
        final dateStr = DateFormat('dd.MM').format(entry.key);
        final moodValue = entry.value.toStringAsFixed(1);
        buffer.writeln('  $dateStr: $moodValue');
      }
      buffer.writeln('');
    }

    // Инсайты
    buffer.writeln('💡 *Инсайты:*');
    if (averageMood >= 4) {
      buffer.writeln('  ✨ У вас отличное настроение в среднем! Продолжайте заботиться о себе.');
    } else if (averageMood >= 3) {
      buffer.writeln('  🌟 Ваше настроение в норме. Есть пространство для улучшения.');
    } else {
      buffer.writeln('  💙 Похоже, вам было непросто. Попробуйте техники релаксации из раздела упражнений.');
    }

    if (streak >= 7) {
      buffer.writeln('  🔥 Отличная серия! Вы отслеживаете настроение уже $streak дней подряд.');
    } else if (streak >= 3) {
      buffer.writeln('  📝 Хороший темп! Серия $streak дней подряд.');
    }

    if (goodDaysPercent >= 70) {
      buffer.writeln('  ☀️ Большинство ваших дней были хорошими! Это замечательно.');
    }

    // Инсайты о сне
    if (sleepRecords.isNotEmpty) {
      if (avgSleepHours < 6) {
        buffer.writeln('  😴 Вы спите в среднем меньше 6 часов. Недостаток сна влияет на настроение и когнитивные функции.');
      } else if (avgSleepHours >= 8) {
        buffer.writeln('  😴 У вас достаточно сна. Это отлично сказывается на ментальном здоровье!');
      }
      
      if (avgSleepQuality >= 4) {
        buffer.writeln('  🌙 Качество сна на высоте! Продолжайте соблюдать гигиену сна.');
      }
    }

    buffer.writeln('');
    buffer.writeln('_Отчёт сгенерирован автоматически для анализа Цитрусом._');

    return buffer.toString();
  }

  /// Парсинг времени из строки "HH:MM:SS" или "HH:MM"
  double? _parseTime(String timeStr) {
    if (!timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + minute / 60.0;
    } catch (e) {
      return null;
    }
  }

  /// Загрузить аналитику и вернуть как объект отчёта
  Future<AnalyticsReport> loadAnalyticsReport({
    required String token,
    required String userId,
    DateTime? startDate,
  }) async {
    _moodRepo.setUserId(userId, token: token);
    _sleepRepo?.setUserId(userId, token: token);

    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));

    final moodRecords = await _moodRepo.getRecords(startDate: start, endDate: now);
    final streak = await _moodRepo.getStreak();
    final goodDaysPercent = await _moodRepo.getGoodDaysPercentage();
    final averageMood = await _moodRepo.getAverageMood();
    final moodByDayMap = await _moodRepo.getAverageMoodByDay(startDate: start, endDate: now);

    // Данные о сне
    List<SleepRecord> sleepRecords = [];
    double avgSleepHours = 0;
    double avgSleepQuality = 0;
    if (_sleepRepo != null) {
      sleepRecords = await _sleepRepo!.getSleepRecords(startDate: start, endDate: now);
      if (sleepRecords.isNotEmpty) {
        final totalHours = sleepRecords.fold<double>(0, (sum, r) {
          if (r.bedTime != null && r.wakeTime != null) {
            final bed = _parseTime(r.bedTime!);
            final wake = _parseTime(r.wakeTime!);
            if (bed != null && wake != null) {
              double hours = wake - bed;
              if (hours < 0) hours += 24;
              return sum + hours;
            }
          }
          return sum;
        });
        avgSleepHours = totalHours / sleepRecords.length;
        avgSleepQuality = sleepRecords.fold<double>(0, (sum, r) => sum + (r.quality ?? 0)) / sleepRecords.length;
      }
    }

    final moodCounts = <int, int>{};
    for (final record in moodRecords) {
      moodCounts[record.moodId] = (moodCounts[record.moodId] ?? 0) + 1;
    }
    final totalMoods = moodRecords.length;

    final moodDistribution = List.generate(6, (i) {
      final count = moodCounts[i] ?? 0;
      final emojis = ['😄', '🙂', '😐', '😟', '😢', '😭'];
      final labels = ['Отлично', 'Хорошо', 'Нормально', 'Плохо', 'Очень плохо', 'Ужасно'];
      final colors = [0xFF4ADE80, 0xFF86EFAC, 0xFFFDE047, 0xFFFB923C, 0xFFF87171, 0xFFDC2626];
      return MoodDistribution(
        emoji: emojis[i],
        label: labels[i],
        count: count,
        percent: totalMoods > 0 ? (count / totalMoods * 100) : 0,
        colorValue: colors[i],
      );
    });

    final sortedEntries = moodByDayMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final moodByDay = sortedEntries.map((entry) {
      final dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
      return MoodDayData(
        dayName: dayNames[entry.key.weekday % 7],
        value: entry.value,
        date: entry.key,
      );
    }).toList();

    return AnalyticsReport(
      period: ReportPeriod(
        label: '${start.day}.${start.month} — ${now.day}.${now.month}',
        startDate: start,
        endDate: now,
      ),
      metrics: ReportMetrics(
        totalDays: now.difference(start).inDays + 1,
        goodDaysPercent: goodDaysPercent,
        averageMood: averageMood,
        streakDays: streak,
        averageSleepHours: avgSleepHours,
        sleepQuality: avgSleepQuality,
        sleepRecords: sleepRecords.length,
      ),
      moodByDay: moodByDay,
      moodDistribution: moodDistribution,
      insights: [],
      activity: ActivityStats(
        moodRecords: moodRecords.length,
        chatMessages: 0,
        exercises: 0,
        tests: 0,
        sleepRecords: sleepRecords.length,
      ),
    );
  }
}
