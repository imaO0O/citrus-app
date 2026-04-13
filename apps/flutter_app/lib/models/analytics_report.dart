/// Модель данных для аналитического отчёта
class AnalyticsReport {
  /// Период отчёта
  final ReportPeriod period;
  
  /// Общие метрики
  final ReportMetrics metrics;
  
  /// Данные о настроении по дням
  final List<MoodDayData> moodByDay;
  
  /// Распределение настроения
  final List<MoodDistribution> moodDistribution;
  
  /// Инсайты
  final List<String> insights;
  
  /// Активность
  final ActivityStats activity;
  
  const AnalyticsReport({
    required this.period,
    required this.metrics,
    required this.moodByDay,
    required this.moodDistribution,
    required this.insights,
    required this.activity,
  });
}

/// Период отчёта
class ReportPeriod {
  final String label; // "Неделя", "Месяц", и т.д.
  final DateTime startDate;
  final DateTime endDate;
  
  const ReportPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
  });
}

/// Общие метрики
class ReportMetrics {
  final int totalDays;
  final double goodDaysPercent;
  final double improvementPercent;
  final int streakDays;
  final double averageMood;
  final double averageSleepHours;
  
  const ReportMetrics({
    this.totalDays = 0,
    this.goodDaysPercent = 0,
    this.improvementPercent = 0,
    this.streakDays = 0,
    this.averageMood = 0,
    this.averageSleepHours = 0,
  });
}

/// Данные о настроении за день
class MoodDayData {
  final String dayName; // "Пн", "Вт", и т.д.
  final double value; // 1-5
  final DateTime date;
  
  const MoodDayData({
    required this.dayName,
    required this.value,
    required this.date,
  });
}

/// Распределение настроения
class MoodDistribution {
  final String emoji;
  final String label;
  final int count;
  final double percent;
  final int colorValue; // Hex цвет для PDF
  
  const MoodDistribution({
    required this.emoji,
    required this.label,
    required this.count,
    required this.percent,
    required this.colorValue,
  });
}

/// Статистика активности
class ActivityStats {
  final int moodRecords;
  final int chatMessages;
  final int exercises;
  final int tests;
  
  const ActivityStats({
    this.moodRecords = 0,
    this.chatMessages = 0,
    this.exercises = 0,
    this.tests = 0,
  });
}
