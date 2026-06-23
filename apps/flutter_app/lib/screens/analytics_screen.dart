import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/citrus_card.dart';
import '../core/widgets/citrus_empty_state.dart';
import '../core/widgets/citrus_line_chart.dart';
import '../services/pdf_report_service.dart';
import '../models/analytics_report.dart';
import '../models/sleep_record.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/sleep_repository.dart';
import '../core/services/storage_service.dart';
import '../core/services/exercise_tracker_service.dart';
import '../core/services/test_tracking_service.dart';
import '../core/config/api_config.dart';
import '../services/stats_api_client.dart';
import '../core/utils/app_size.dart';
import 'models/mood.dart';

/// День с парой «часы сна ↔ среднее настроение» для корреляции.
class _SleepMoodDay {
  final DateTime date;
  final double sleepHours;
  final double avgMood; // 0 (отлично) … 5 (очень плохо)
  _SleepMoodDay({required this.date, required this.sleepHours, required this.avgMood});
}

/// Точка истории клинического теста: дата прохождения и суммарный балл.
class _TestPoint {
  final DateTime date;
  final int total;
  _TestPoint({required this.date, required this.total});
}

/// Тренд по клиническому тесту (PHQ-9 / GAD-7).
class _TestTrend {
  final String testId;
  final String title;
  final int maxScore;
  final List<_TestPoint> points; // по возрастанию даты
  _TestTrend({required this.testId, required this.title, required this.maxScore, required this.points});
}

/// Зона тяжести на шкале клинического теста.
class _SeverityBand {
  final int upTo; // верхняя граница зоны (включительно)
  final String label;
  final Color color;
  const _SeverityBand(this.upTo, this.label, this.color);
}

const List<String> _ruMonths = [
  'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
];

/// Клинические тесты с единым баллом (выше = хуже).
const Map<String, Map<String, Object>> _clinicalTests = {
  'phq9': {'title': 'PHQ-9 · депрессия', 'max': 27},
  'gad7': {'title': 'GAD-7 · тревожность', 'max': 21},
};

class AnalyticsScreen extends StatefulWidget {
  AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['\u041D\u0435\u0434\u0435\u043B\u044F', '\u041C\u0435\u0441\u044F\u0446', '3 \u043C\u0435\u0441', '\u0413\u043E\u0434'];
  bool _isGeneratingPdf = false;
  bool _isLoading = true;
  bool _loadError = false;
  AnalyticsReport? _report;
  List<_SleepMoodDay> _sleepMoodDays = [];
  List<_TestTrend> _testTrends = [];

  @override
  void initState() {
    super.initState();
    // Загружаем данные сразу при инициализации (период по умолчанию = неделя)
    // Используем Future.microtask чтобы дождаться полной инициализации контекста
    Future.microtask(() {
      if (mounted) {
        _loadReportData();
      }
    });
  }

  /// Публичный метод для принудительного обновления данных (вызывается при навигации)
  void refreshData() {
    // Сбрасываем состояние для показа индикатора загрузки
    setState(() {
      _isLoading = true;
    });
    // Всегда загружаем свежие данные из БД
    _loadReportData();
  }

  /// Сбросить период без перезагрузки данных (для оптимизации)
  void _setPeriod(int period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    _loadReportData();
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

  Future<void> _loadReportData() async {
    debugPrint('============= ANALYTICS _loadReportData CALLED =============');
    setState(() {
      _isLoading = true;
      _loadError = false;
    });

    try {
      // Используем репозитории из Provider
      final moodRepo = context.read<MoodRepository>();
      final sleepRepo = context.read<SleepRepository>();

      final userId = moodRepo.userId;
      final isAuth = userId != 'unknown';

      debugPrint('============= ANALYTICS LOAD START =============');
      debugPrint('Analytics: userId=$userId, isAuth=$isAuth');
      debugPrint('Analytics: selectedPeriod=$_selectedPeriod');

      if (!isAuth) {
        debugPrint('Analytics: NOT AUTHORIZED - showing empty state');
        // Без авторизации не показываем чужие/выдуманные цифры — пустое состояние.
        if (mounted) {
          setState(() {
            _report = null;
            _isLoading = false;
          });
        }
        return;
      }

      final now = DateTime.now();
      final daysBack = _selectedPeriod == 0 ? 7 : _selectedPeriod == 1 ? 30 : _selectedPeriod == 2 ? 90 : 365;
      final startDate = now.subtract(Duration(days: daysBack));

      // Загружаем записи настроения
      final moodRecords = await moodRepo.getRecords(startDate: startDate, endDate: now);
      debugPrint('Analytics: moodRecords count = ${moodRecords.length}');

      // Вычисляем метрики
      final streak = await moodRepo.getStreak();
      final averageMood = await moodRepo.getAverageMood();

      // Загружаем записи сна
      List<SleepRecord> sleepRecords = [];
      try {
        sleepRecords = await sleepRepo.getSleepRecords(startDate: startDate, endDate: now);
        debugPrint('Analytics: sleepRecords count = ${sleepRecords.length}');
      } catch (e) {
        debugPrint('Analytics: error loading sleep records: $e');
        // Если ошибка авторизации — пробуем загрузить через StorageService
        try {
          final storage = StorageService();
          final token = await storage.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            sleepRepo.setUserId(userId, token: token);
            debugPrint('Analytics: retrying sleepRepo with token from storage');
            sleepRecords = await sleepRepo.getSleepRecords(startDate: startDate, endDate: now);
            debugPrint('Analytics: sleepRecords count (retry) = ${sleepRecords.length}');
          }
        } catch (e2) {
          debugPrint('Analytics: retry sleep load failed: $e2');
        }
      }

      // Загружаем количество пройденных тестов
      int testsCount = 0;
      try {
        testsCount = await _getTestsCount();
        debugPrint('Analytics: tests count = $testsCount');
      } catch (e) {
        debugPrint('Error loading test results: $e');
      }

      // Загружаем количество выполненных упражнений
      int exercisesCount = 0;
      try {
        exercisesCount = await _getExercisesCount();
        debugPrint('Analytics: exercises count = $exercisesCount');
      } catch (e) {
        debugPrint('Error loading exercises count: $e');
      }

      // Загружаем количество сообщений чата
      int chatMessagesCount = 0;
      try {
        final storage = StorageService();
        final token = await storage.getString('auth_token');
        chatMessagesCount = await _getChatMessagesCount(token);
        debugPrint('Analytics: chat messages count = $chatMessagesCount');
      } catch (e) {
        debugPrint('Error loading chat messages count: $e');
      }

      // Загружаем данные о сне
      int sleepRecordsCount = sleepRecords.length;
      double avgSleepHours = 0;
      double avgSleepQuality = 0;
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

      debugPrint('Analytics: FINAL ACTIVITY -> moods=${moodRecords.length}, chat=$chatMessagesCount, exercises=$exercisesCount, tests=$testsCount, sleep=$sleepRecordsCount');
      debugPrint('Analytics: FINAL SLEEP -> records=$sleepRecordsCount, avgHours=$avgSleepHours, avgQuality=$avgSleepQuality');
      debugPrint('============= ANALYTICS LOAD SUCCESS =============');

      // Строим данные по дням для графика
      final moodByDayMap = await moodRepo.getAverageMoodByDay(startDate: startDate, endDate: now);
      final dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
      
      // Сортируем по дате и берём все данные за период
      final sortedEntries = moodByDayMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      
      final moodByDay = sortedEntries.map((entry) {
        return MoodDayData(
          dayName: dayNames[entry.key.weekday % 7],
          value: entry.value,
          date: entry.key,
        );
      }).toList();

      // Распределение настроения (все 6 уровней)
      final moodCounts = <int, int>{};
      for (final record in moodRecords) {
        moodCounts[record.moodId] = (moodCounts[record.moodId] ?? 0) + 1;
      }
      final totalMoods = moodRecords.length;
      final moodDistribution = [
        MoodDistribution(
          emoji: '\u{1F604}',
          label: '\u041E\u0442\u043B\u0438\u0447\u043D\u043E',
          count: moodCounts[0] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[0] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFF8BC34A,
        ),
        MoodDistribution(
          emoji: '\u{1F642}',
          label: '\u0425\u043E\u0440\u043E\u0448\u043E',
          count: moodCounts[1] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[1] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFFFFD93D,
        ),
        MoodDistribution(
          emoji: '\u{1F610}',
          label: '\u041D\u043E\u0440\u043C\u0430\u043B\u044C\u043D\u043E',
          count: moodCounts[2] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[2] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFFFF8C42,
        ),
        MoodDistribution(
          emoji: '\u{1F61F}',
          label: '\u0422\u0440\u0435\u0432\u043E\u0436\u043D\u043E',
          count: moodCounts[3] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[3] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFFFFA726,
        ),
        MoodDistribution(
          emoji: '\u{1F622}',
          label: '\u041F\u043B\u043E\u0445\u043E',
          count: moodCounts[4] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[4] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFFFF5B5B,
        ),
        MoodDistribution(
          emoji: '\u{1F61E}',
          label: '\u041E\u0447\u0435\u043D\u044C \u043F\u043B\u043E\u0445\u043E',
          count: moodCounts[5] ?? 0,
          percent: totalMoods > 0 ? ((moodCounts[5] ?? 0) / totalMoods * 100) : 0,
          colorValue: 0xFFE63946,
        ),
      ];

      final sleepMoodDays = _computeSleepMood(moodRecords, sleepRecords);

      List<_TestTrend> testTrends = [];
      try {
        final storage = StorageService();
        final token = await storage.getString('auth_token');
        testTrends = await _loadTestTrends(token);
      } catch (e) {
        debugPrint('Error loading test trends: $e');
      }

      // Хороших дней за период + тренд к прошлому периоду (для геройской метрики)
      double goodPctOf(Map<DateTime, double> m) =>
          m.isEmpty ? 0 : m.values.where((v) => v <= 2.0).length / m.length * 100;
      final periodGoodPct = goodPctOf(moodByDayMap);
      double trendPp = 0;
      try {
        final prevStart = startDate.subtract(Duration(days: daysBack));
        final prevMap = await moodRepo.getAverageMoodByDay(startDate: prevStart, endDate: startDate);
        if (prevMap.isNotEmpty) trendPp = periodGoodPct - goodPctOf(prevMap);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _sleepMoodDays = sleepMoodDays;
          _testTrends = testTrends;
          _report = AnalyticsReport(
            period: ReportPeriod(
              label: _periods[_selectedPeriod],
              startDate: startDate,
              endDate: now,
            ),
            metrics: ReportMetrics(
              totalDays: daysBack,
              goodDaysPercent: periodGoodPct,
              improvementPercent: trendPp,
              streakDays: streak,
              averageMood: averageMood,
              averageSleepHours: avgSleepHours,
              sleepQuality: avgSleepQuality,
              sleepRecords: sleepRecordsCount,
            ),
            moodByDay: moodByDay,
            moodDistribution: moodDistribution,
            insights: _generateInsights(moodRecords, sleepRecords, averageMood, avgSleepHours),
            activity: ActivityStats(
              moodRecords: moodRecords.length,
              chatMessages: chatMessagesCount,
              exercises: exercisesCount,
              tests: testsCount,
              sleepRecords: sleepRecordsCount,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _report = null;
          _loadError = true;
          _isLoading = false;
        });
      }
    }
  }

  List<String> _generateInsights(
    List<MoodRecord> moods,
    List<dynamic> sleeps,
    double avgMood,
    double avgSleep,
  ) {
    final insights = <String>[];
    
    if (avgMood >= 4) {
      insights.add('\u0412\u0430\u0448\u0435 \u0441\u0440\u0435\u0434\u043D\u0435\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u043E\u0442\u043B\u0438\u0447\u043D\u043E\u0435! \u041F\u0440\u043E\u0434\u043E\u043B\u0436\u0430\u0439\u0442\u0435 \u0432 \u0442\u043E\u043C \u0436\u0435 \u0434\u0443\u0445\u0435.');
    } else if (avgMood >= 3) {
      insights.add('\u0412\u0430\u0448\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u0441\u0442\u0430\u0431\u0438\u043B\u044C\u043D\u043E\u0435. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0434\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u0431\u043E\u043B\u044C\u0448\u0435 \u043F\u043E\u043B\u043E\u0436\u0438\u0442\u0435\u043B\u044C\u043D\u044B\u0445 \u0430\u043A\u0442\u0438\u0432\u043D\u043E\u0441\u0442\u0435\u0439.');
    } else {
      insights.add('\u041F\u043E\u0445\u043E\u0436\u0435, \u0432\u0430\u0448\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u043C\u043E\u0436\u043D\u043E \u0443\u043B\u0443\u0447\u0448\u0438\u0442\u044C. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F \u043D\u0430 \u0434\u044B\u0445\u0430\u043D\u0438\u0435.');
    }

    if (avgSleep >= 7) {
      insights.add('\u0412\u044B \u0441\u043F\u0438\u0442\u0435 \u0434\u043E\u0441\u0442\u0430\u0442\u043E\u0447\u043D\u043E! \u0425\u043E\u0440\u043E\u0448\u0438\u0439 \u0441\u043E\u043D \u043F\u043E\u043B\u043E\u0436\u0438\u0442\u0435\u043B\u044C\u043D\u043E \u0432\u043B\u0438\u044F\u0435\u0442 \u043D\u0430 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435.');
    } else if (avgSleep > 0) {
      insights.add('\u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0441\u043F\u0430\u0442\u044C \u043D\u0435\u043C\u043D\u043E\u0433\u043E \u0431\u043E\u043B\u044C\u0448\u0435. \u0420\u0435\u043A\u043E\u043C\u0435\u043D\u0434\u0443\u0435\u0442\u0441\u044F 7-9 \u0447\u0430\u0441\u043E\u0432 \u0441\u043D\u0430.');
    }

    if (moods.length >= 5) {
      insights.add('\u0412\u044B \u0430\u043A\u0442\u0438\u0432\u043D\u043E \u043E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0435\u0442\u0435 \u0441\u0432\u043E\u0451 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435. \u042D\u0442\u043E \u043F\u043E\u043C\u043E\u0433\u0430\u0435\u0442 \u043B\u0443\u0447\u0448\u0435 \u043F\u043E\u043D\u0438\u043C\u0430\u0442\u044C \u0441\u0435\u0431\u044F!');
    }

    if (insights.isEmpty) {
      insights.add('\u041D\u0430\u0447\u043D\u0438\u0442\u0435 \u043E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0442\u044C \u0441\u0432\u043E\u0451 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u0440\u0435\u0433\u0443\u043B\u044F\u0440\u043D\u043E \u0434\u043B\u044F \u043F\u043E\u043B\u0443\u0447\u0435\u043D\u0438\u044F \u043F\u0435\u0440\u0441\u043E\u043D\u0430\u043B\u044C\u043D\u044B\u0445 \u0438\u043D\u0441\u0430\u0439\u0442\u043E\u0432.');
    }

    return insights;
  }

  /// Период в родительном падеже для заголовка графика.
  String _periodGenitive() {
    switch (_selectedPeriod) {
      case 0:
        return 'неделю';
      case 1:
        return 'месяц';
      case 2:
        return '3 месяца';
      default:
        return 'год';
    }
  }

  /// Сгенерировать и показать PDF отчёт
  Future<void> _generatePdfReport() async {
    if (_isGeneratingPdf || _report == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      // Генерируем PDF из реальных данных
      final pdfService = PdfReportService();
      final doc = await pdfService.generateReport(_report!);

      // Показываем диалог предпросмотра
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'citrus_analytics_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при генерации PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  /// Получить количество пройденных тестов из БД (psychological_test_results)
  Future<int> _getTestsCount() async {
    try {
      final storage = StorageService();
      final token = await storage.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        // Fallback на локальное хранилище
        return await TestTrackingService().getTestsCount();
      }

      final statsApi = StatsApiClient(
        baseUrl: ApiConfig.baseUrl,
        token: token,
      );
      
      return await statsApi.getTestsCountFromDB();
    } catch (e) {
      debugPrint('Error getting tests count from DB, using local: $e');
      return await TestTrackingService().getTestsCount();
    }
  }

  /// Получить количество выполненных упражнений из БД (user_exercises)
  Future<int> _getExercisesCount() async {
    try {
      final storage = StorageService();
      final token = await storage.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        // Fallback на локальное хранилище
        return await ExerciseTrackerService().getExercisesCount();
      }

      final statsApi = StatsApiClient(
        baseUrl: ApiConfig.baseUrl,
        token: token,
      );
      
      final stats = await statsApi.getExerciseStats();
      return stats['totalExercises'] as int;
    } catch (e) {
      debugPrint('Error getting exercises count from DB, using local: $e');
      return await ExerciseTrackerService().getExercisesCount();
    }
  }

  /// Получить количество сообщений чата из БД (chat_messages)
  Future<int> _getChatMessagesCount(String? token) async {
    if (token == null || token.isEmpty) return 0;

    try {
      // Используем /analytics/stats endpoint который возвращает chatMessages
      final url = Uri.parse('${ApiConfig.baseUrl}/analytics/stats');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['chatMessages'] as int;
      }
    } catch (e) {
      debugPrint('Error getting chat messages count from DB: $e');
    }
    
    return 0;
  }

  /// Нет ли в отчёте ни одной активности (новый пользователь / пустой период).
  bool get _reportIsEmpty {
    final r = _report;
    if (r == null) return true;
    final a = r.activity;
    return a.moodRecords == 0 &&
        a.sleepRecords == 0 &&
        a.tests == 0 &&
        a.exercises == 0 &&
        a.chatMessages == 0;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('analytics_screen'),
      onVisibilityChanged: (info) {
        // Обновляем данные когда экран становится полностью видимым
        if (info.visibleFraction == 1.0 && !_isLoading) {
          debugPrint('Analytics: screen became fully visible, refreshing data...');
          _loadReportData();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
                      ),
                      AppSize.gapH(16),
                      Text(
                        'Загрузка аналитики...',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
                      ),
                    ],
                  ),
                )
              : _loadError
              ? _buildErrorView()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 480),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                AppSize.gapH(16),
                                _buildPeriodSelector(),
                                AppSize.gapH(16),
                                if (_report == null || _reportIsEmpty)
                                  _buildEmptyView()
                                else ...[
                                  _buildHero(),
                                  AppSize.gapH(16),
                                  _buildOverviewCards(),
                                  AppSize.gapH(20),
                                  _buildMoodChart(),
                                  AppSize.gapH(20),
                                  _buildMoodDistribution(),
                                  AppSize.gapH(20),
                                  _buildInsights(),
                                  AppSize.gapH(20),
                                  _buildSleepSection(),
                                  AppSize.gapH(20),
                                  _buildSleepMoodCorrelation(),
                                  AppSize.gapH(20),
                                  _buildTestDynamics(),
                                  _buildActivitySection(),
                                  AppSize.gapH(20),
                                  _buildExportButtons(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(padding: AppSize.paddingOnly(bottom: 80)),
                  ],
                ),
        ),
      ),
    );
  }

  /// Сопоставляет ночи сна и среднее настроение по дате для корреляции.
  List<_SleepMoodDay> _computeSleepMood(
    List<MoodRecord> moods,
    List<SleepRecord> sleeps,
  ) {
    final moodByDay = <String, List<int>>{};
    for (final m in moods) {
      moodByDay.putIfAbsent(_dayKey(m.moodDate), () => []).add(m.moodId);
    }
    final result = <_SleepMoodDay>[];
    for (final s in sleeps) {
      final hours = _sleepHours(s);
      if (hours <= 0) continue;
      final moodList = moodByDay[_dayKey(s.sleepDate)];
      if (moodList == null || moodList.isEmpty) continue;
      final avgMood = moodList.reduce((a, b) => a + b) / moodList.length;
      result.add(_SleepMoodDay(date: s.sleepDate, sleepHours: hours, avgMood: avgMood));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  double _sleepHours(SleepRecord r) {
    if (r.bedTime == null || r.wakeTime == null) return 0;
    double? parse(String t) {
      final p = t.split(':');
      if (p.length < 2) return null;
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h == null || m == null) return null;
      return h + m / 60.0;
    }
    final bed = parse(r.bedTime!);
    final wake = parse(r.wakeTime!);
    if (bed == null || wake == null) return 0;
    var hours = wake - bed;
    if (hours < 0) hours += 24;
    return hours;
  }

  /// Коэффициент Пирсона между часами сна и moodId (0=отлично…5=плохо).
  /// Отрицательный r = больше сна → ниже moodId → лучше настроение.
  double? _pearson(List<_SleepMoodDay> days) {
    final n = days.length;
    if (n < 3) return null;
    final xs = days.map((d) => d.sleepHours).toList();
    final ys = days.map((d) => d.avgMood).toList();
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    double sxy = 0, sxx = 0, syy = 0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - mx;
      final dy = ys[i] - my;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
    }
    if (sxx == 0 || syy == 0) return null;
    return sxy / (sqrt(sxx) * sqrt(syy));
  }

  Widget _buildSleepMoodCorrelation() {
    final days = _sleepMoodDays;

    Widget card(Widget child) => Container(
          width: double.infinity,
          padding: AppSize.padding(16),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, size: AppSize.s(18), color: AppColors.citrusPurple),
                  AppSize.gapW(8),
                  Text('Сон и настроение',
                      style: TextStyle(
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground)),
                ],
              ),
              AppSize.gapH(12),
              child,
            ],
          ),
        );

    if (days.length < 3) {
      return card(Text(
        'Отмечайте сон и настроение хотя бы несколько дней подряд — здесь появится связь между качеством сна и вашим состоянием.',
        style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground, height: 1.5),
      ));
    }

    final shortNights = days.where((d) => d.sleepHours < 7).toList();
    final goodNights = days.where((d) => d.sleepHours >= 7).toList();
    double? avgOf(List<_SleepMoodDay> l) =>
        l.isEmpty ? null : l.map((e) => e.avgMood).reduce((a, b) => a + b) / l.length;
    final shortAvg = avgOf(shortNights);
    final goodAvg = avgOf(goodNights);
    final r = _pearson(days);

    String insight;
    if (shortAvg != null && goodAvg != null) {
      final diff = shortAvg - goodAvg; // >0: после короткого сна настроение хуже
      if (diff > 0.4) {
        insight = 'После полноценного сна (≥ 7 ч) ваше настроение заметно лучше. Сон стоит беречь 💤';
      } else if (diff < -0.4) {
        insight = 'Пока более долгий сон не улучшает ваше настроение — понаблюдайте ещё.';
      } else {
        insight = 'Связь между длительностью сна и настроением у вас выражена слабо.';
      }
    } else {
      insight = goodAvg == null
          ? 'Пока мало ночей с полноценным сном (≥ 7 ч) для сравнения.'
          : 'Пока мало ночей с коротким сном (< 7 ч) для сравнения.';
    }

    return card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shortAvg != null) _moodSleepRow('После сна < 7 ч', shortAvg, shortNights.length),
        if (shortAvg != null) AppSize.gapH(8),
        if (goodAvg != null) _moodSleepRow('После сна ≥ 7 ч', goodAvg, goodNights.length),
        AppSize.gapH(12),
        if (r != null) ...[
          Text('Коэффициент корреляции: r = ${r.toStringAsFixed(2)}',
              style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
          AppSize.gapH(8),
        ],
        Text(insight,
            style: TextStyle(fontSize: AppSize.s(13), color: AppColors.mutedForeground, height: 1.5)),
      ],
    ));
  }

  Widget _moodSleepRow(String label, double avgMood, int count) {
    final mood = Mood.all[avgMood.round().clamp(0, 5)];
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: AppSize.s(13), color: AppColors.foreground)),
        ),
        Text(mood.emoji, style: TextStyle(fontSize: AppSize.s(18))),
        AppSize.gapW(6),
        Text(mood.label,
            style: TextStyle(
                fontSize: AppSize.s(13), fontWeight: FontWeight.w600, color: mood.color)),
        AppSize.gapW(6),
        Text('($count)',
            style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
      ],
    );
  }

  /// Загружает историю клинических тестов и собирает тренды (суммарный балл по датам).
  Future<List<_TestTrend>> _loadTestTrends(String? token) async {
    if (token == null || token.isEmpty) return [];
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tests/results'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List<dynamic>;
      final byTest = <String, List<_TestPoint>>{};
      for (final item in list) {
        if (item is! Map) continue;
        final testId = item['testId'] as String?;
        if (testId == null || !_clinicalTests.containsKey(testId)) continue;
        final rawScores = item['scores'];
        Map<String, dynamic> scores;
        if (rawScores is String) {
          scores = jsonDecode(rawScores) as Map<String, dynamic>;
        } else if (rawScores is Map) {
          scores = Map<String, dynamic>.from(rawScores);
        } else {
          continue;
        }
        var total = 0;
        for (final v in scores.values) {
          if (v is num) total += v.toInt();
        }
        final date = DateTime.tryParse('${item['completedAt']}');
        if (date == null) continue;
        byTest.putIfAbsent(testId, () => []).add(_TestPoint(date: date, total: total));
      }
      final trends = <_TestTrend>[];
      byTest.forEach((testId, points) {
        points.sort((a, b) => a.date.compareTo(b.date));
        final meta = _clinicalTests[testId]!;
        trends.add(_TestTrend(
          testId: testId,
          title: meta['title'] as String,
          maxScore: meta['max'] as int,
          points: points,
        ));
      });
      return trends;
    } catch (e) {
      debugPrint('Error loading test trends: $e');
      return [];
    }
  }

  Widget _buildTestDynamics() {
    final trends = _testTrends.where((t) => t.points.isNotEmpty).toList();
    if (trends.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: AppSize.padding(16),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, size: AppSize.s(18), color: AppColors.citrusOrange),
                  AppSize.gapW(8),
                  Text('Динамика тестов',
                      style: TextStyle(
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground)),
                ],
              ),
              AppSize.gapH(4),
              Text('Чем ниже балл — тем лучше состояние',
                  style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
              AppSize.gapH(12),
              ...trends.map(_buildTrendItem),
              Text(
                'Это скрининг, а не диагноз. При устойчивом ухудшении обратитесь к специалисту.',
                style: TextStyle(fontSize: AppSize.s(10), color: AppColors.dimForeground, height: 1.4),
              ),
            ],
          ),
        ),
        AppSize.gapH(20),
      ],
    );
  }

  /// Зоны тяжести для шкалы (выше = хуже). Цвета — из палитры Mood/citrus.
  List<_SeverityBand> _bandsFor(String testId) {
    if (testId == 'gad7') {
      return [
        _SeverityBand(4, 'Минимальная', AppColors.citrusGreen),
        _SeverityBand(9, 'Лёгкая', AppColors.citrusYellow),
        _SeverityBand(14, 'Умеренная', AppColors.citrusAmber),
        _SeverityBand(21, 'Тяжёлая', AppColors.destructive),
      ];
    }
    return [
      _SeverityBand(4, 'Минимальная', AppColors.citrusGreen),
      _SeverityBand(9, 'Лёгкая', AppColors.citrusYellow),
      _SeverityBand(14, 'Умеренная', AppColors.citrusAmber),
      _SeverityBand(19, 'Умеренно-тяжёлая', AppColors.citrusOrange),
      _SeverityBand(27, 'Тяжёлая', AppColors.destructive),
    ];
  }

  String _fmtDate(DateTime d) => '${d.day} ${_ruMonths[d.month - 1]}';

  Widget _buildTrendItem(_TestTrend t) {
    final bands = _bandsFor(t.testId);
    final latest = t.points.last;
    final band = bands.firstWhere((b) => latest.total <= b.upTo, orElse: () => bands.last);
    final fraction = (latest.total / t.maxScore).clamp(0.0, 1.0).toDouble();

    // Сегменты шкалы тяжести (ширина пропорциональна диапазону зоны)
    final segments = <Widget>[];
    var prevMax = -1;
    for (final b in bands) {
      final span = b.upTo - prevMax;
      prevMax = b.upTo;
      segments.add(Expanded(
        flex: span,
        child: Container(height: AppSize.s(12), color: b.color),
      ));
    }

    // Подпись динамики между прохождениями
    final prev = t.points.length >= 2 ? t.points[t.points.length - 2] : null;
    Widget footer;
    if (prev != null) {
      final diff = latest.total - prev.total;
      late Color c;
      late IconData icon;
      late String text;
      if (diff >= 3) {
        c = AppColors.destructive;
        icon = Icons.arrow_upward;
        text = '+$diff с прошлого — если так держится, подумайте о поддержке';
      } else if (diff <= -3) {
        c = AppColors.citrusGreen;
        icon = Icons.arrow_downward;
        text = '−${-diff} с прошлого — хорошая динамика';
      } else {
        c = AppColors.mutedForeground;
        icon = Icons.remove;
        text = 'как в прошлый раз';
      }
      footer = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSize.s(13), color: c),
          AppSize.gapW(4),
          Expanded(
            child: Text('$text · ${_fmtDate(prev.date)} → ${_fmtDate(latest.date)}',
                style: TextStyle(fontSize: AppSize.s(11), color: c)),
          ),
        ],
      );
    } else {
      footer = Text('первое прохождение · ${_fmtDate(latest.date)}',
          style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground));
    }

    return Padding(
      padding: AppSize.paddingOnly(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.title,
                    style: TextStyle(
                        fontSize: AppSize.s(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground)),
              ),
              Text('${latest.total}',
                  style: TextStyle(
                      fontSize: AppSize.s(15),
                      fontWeight: FontWeight.w700,
                      color: band.color)),
              Text(' / ${t.maxScore}',
                  style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
            ],
          ),
          AppSize.gapH(9),
          SizedBox(
            height: AppSize.s(12),
            child: Align(
              alignment: Alignment(fraction * 2 - 1, 1),
              child: Icon(Icons.arrow_drop_down, size: AppSize.s(20), color: AppColors.foreground),
            ),
          ),
          ClipRRect(
            borderRadius: AppSize.radius(7),
            child: Row(children: segments),
          ),
          AppSize.gapH(10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: AppSize.paddingH(10, 3),
              decoration: BoxDecoration(
                color: band.color.withValues(alpha: 0.15),
                borderRadius: AppSize.radius(8),
              ),
              child: Text(band.label,
                  style: TextStyle(
                      fontSize: AppSize.s(12),
                      fontWeight: FontWeight.w500,
                      color: band.color)),
            ),
          ),
          AppSize.gapH(8),
          footer,
        ],
      ),
    );
  }

  /// \u0421\u043E\u0441\u0442\u043E\u044F\u043D\u0438\u0435 \u043E\u0448\u0438\u0431\u043A\u0438 \u0437\u0430\u0433\u0440\u0443\u0437\u043A\u0438: \u0431\u0435\u0437 \u0432\u044B\u0434\u0443\u043C\u0430\u043D\u043D\u044B\u0445 \u0446\u0438\u0444\u0440, \u0441 \u043A\u043D\u043E\u043F\u043A\u043E\u0439 \u00AB\u041F\u043E\u0432\u0442\u043E\u0440\u0438\u0442\u044C\u00BB.
  Widget _buildErrorView() {
    return CitrusEmptyState(
      emoji: '\uD83D\uDE15',
      title: '\u041D\u0435 \u0443\u0434\u0430\u043B\u043E\u0441\u044C \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044C',
      subtitle: '\u041F\u0440\u043E\u0432\u0435\u0440\u044C\u0442\u0435 \u043F\u043E\u0434\u043A\u043B\u044E\u0447\u0435\u043D\u0438\u0435 \u043A \u0438\u043D\u0442\u0435\u0440\u043D\u0435\u0442\u0443 \u0438 \u043F\u043E\u043F\u0440\u043E\u0431\u0443\u0439\u0442\u0435 \u0441\u043D\u043E\u0432\u0430.',
      actionLabel: '\u041F\u043E\u0432\u0442\u043E\u0440\u0438\u0442\u044C',
      actionIcon: Icons.refresh,
      onAction: _loadReportData,
    );
  }

  /// \u041F\u0443\u0441\u0442\u043E\u0435 \u0441\u043E\u0441\u0442\u043E\u044F\u043D\u0438\u0435 \u0434\u043B\u044F \u043D\u043E\u0432\u043E\u0433\u043E \u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044F \u0438\u043B\u0438 \u043F\u0435\u0440\u0438\u043E\u0434\u0430 \u0431\u0435\u0437 \u0434\u0430\u043D\u043D\u044B\u0445.
  Widget _buildEmptyView() {
    return Padding(
      padding: AppSize.paddingOnly(top: 40),
      child: const CitrusEmptyState(
        emoji: '\uD83C\uDF31',
        title: '\u041F\u043E\u043A\u0430 \u043D\u0435\u0442 \u0434\u0430\u043D\u043D\u044B\u0445',
        subtitle:
            '\u041E\u0442\u043C\u0435\u0447\u0430\u0439\u0442\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435, \u0441\u043E\u043D \u0438 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F \u2014 \u0437\u0434\u0435\u0441\u044C \u043F\u043E\u044F\u0432\u0438\u0442\u0441\u044F \u0432\u0430\u0448\u0430 \u043B\u0438\u0447\u043D\u0430\u044F \u0441\u0442\u0430\u0442\u0438\u0441\u0442\u0438\u043A\u0430 \u0438 \u0438\u043D\u0441\u0430\u0439\u0442\u044B.',
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('\u0410\u043D\u0430\u043B\u0438\u0442\u0438\u043A\u0430', style: AppText.displayTitle),
        AppSize.gapH(4),
        Text('\u041E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0439\u0442\u0435 \u0441\u0432\u043E\u0439 \u043F\u0440\u043E\u0433\u0440\u0435\u0441\u0441', style: AppText.caption),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: AppSize.padding(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(12),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = index == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setPeriod(index),
              child: Container(
                padding: AppSize.paddingH(0, 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.citrusOrange.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: AppSize.radius(10),
                ),
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSize.s(12),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// \u0413\u0435\u0440\u043E\u0439\u0441\u043A\u0430\u044F \u043C\u0435\u0442\u0440\u0438\u043A\u0430: \u043A\u0440\u0443\u043F\u043D\u044B\u0439 % \u0445\u043E\u0440\u043E\u0448\u0438\u0445 \u0434\u043D\u0435\u0439 + \u0442\u0440\u0435\u043D\u0434 \u043A \u043F\u0440\u043E\u0448\u043B\u043E\u043C\u0443 \u043F\u0435\u0440\u0438\u043E\u0434\u0443
  /// (\u043F\u0430\u0442\u0442\u0435\u0440\u043D \u0444\u0438\u043D\u0442\u0435\u0445-\u0434\u044D\u0448\u0431\u043E\u0440\u0434\u043E\u0432 Copilot/Mercury).
  Widget _buildHero() {
    if (_report == null) return const SizedBox.shrink();
    final m = _report!.metrics;
    final trend = m.improvementPercent;
    final flat = trend.abs() < 0.5;
    final up = trend >= 0;
    final tColor = flat ? AppColors.mutedForeground : (up ? AppColors.citrusGreen : AppColors.destructive);
    final tIcon = flat ? Icons.remove : (up ? Icons.arrow_upward : Icons.arrow_downward);
    final tText = flat ? '\u0431\u0435\u0437 \u0438\u0437\u043C\u0435\u043D\u0435\u043D\u0438\u0439' : '${up ? '+' : '\u2212'}${trend.abs().toStringAsFixed(0)} \u043F\u043F';

    return CitrusCard(
      accent: AppColors.citrusOrange,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.citrusOrange.withValues(alpha: 0.14), AppColors.citrusAmber.withValues(alpha: 0.05)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u0425\u043E\u0440\u043E\u0448\u0438\u0445 \u0434\u043D\u0435\u0439 \u0437\u0430 ${_periodGenitive()}', style: AppText.caption),
          AppSize.gapH(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${m.goodDaysPercent.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: AppSize.s(40), fontWeight: FontWeight.w800, color: AppColors.foreground, height: 1),
              ),
              AppSize.gapW(10),
              Padding(
                padding: AppSize.paddingOnly(bottom: 7),
                child: Container(
                  padding: AppSize.paddingH(10, 5),
                  decoration: BoxDecoration(color: tColor.withValues(alpha: 0.15), borderRadius: AppSize.radius(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(tIcon, size: AppSize.s(13), color: tColor),
                    AppSize.gapW(3),
                    Text(tText, style: TextStyle(color: tColor, fontSize: AppSize.s(12), fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ],
          ),
          AppSize.gapH(2),
          Text('\u043A \u043F\u0440\u043E\u0448\u043B\u043E\u043C\u0443 \u043F\u0435\u0440\u0438\u043E\u0434\u0443', style: AppText.label),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (_report == null) return SizedBox.shrink();

    final m = _report!.metrics;
    final a = _report!.activity;
    final avgMood = Mood.all[m.averageMood.round().clamp(0, 5)];
    final items = <(IconData, Color, String, String)>[
      (Icons.event_available, AppColors.citrusOrange, '${m.totalDays}', '\u0414\u043D\u0435\u0439 \u0432 \u043F\u0435\u0440\u0438\u043E\u0434\u0435'),
      (Icons.local_fire_department, AppColors.citrusAmber, '${m.streakDays}', '\u0421\u0435\u0440\u0438\u044F \u0434\u043D\u0435\u0439'),
      (Icons.favorite, avgMood.color, avgMood.emoji, '\u0421\u0440\u0435\u0434\u043D\u0435\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435'),
      (Icons.edit_note, AppColors.citrusPurple, '${a.moodRecords}', '\u041E\u0442\u043C\u0435\u0442\u043E\u043A \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final it = items[index];
        return _statCard(it.$1, it.$2, it.$3, it.$4);
      },
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String label) {
    return CitrusCard(
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: AppSize.s(34),
            height: AppSize.s(34),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: AppSize.radius(10)),
            child: Icon(icon, color: color, size: AppSize.s(18)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: AppSize.s(22), fontWeight: FontWeight.w800, color: AppColors.foreground)),
              AppSize.gapH(2),
              Text(label, style: AppText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    if (_report == null) return SizedBox.shrink();

    final moodByDay = _report!.moodByDay;
    
    if (moodByDay.isEmpty) {
      return Container(
        padding: AppSize.padding(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: AppSize.radius(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Center(
          child: Text(
            'Нет данных о настроении за выбранный период',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
          ),
        ),
      );
    }

    final days = moodByDay.map((d) => d.dayName).toList();
    final values = moodByDay.map((d) => d.value).toList();

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u041D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435 \u0437\u0430 ${_periodGenitive()}',
            style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          AppSize.gapH(2),
          Text('\u0432\u044B\u0448\u0435 \u0441\u0442\u043E\u043B\u0431\u0438\u043A \u2014 \u043B\u0443\u0447\u0448\u0435 \u0434\u0435\u043D\u044C',
              style: TextStyle(fontSize: AppSize.s(11), color: AppColors.dimForeground)),
          AppSize.gapH(16),
          CitrusLineChart(
            values: values.map<double?>((v) => 5 - v).toList(),
            minY: 0,
            maxY: 5,
            color: AppColors.citrusOrange,
            labels: days.length <= 14 ? days : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution() {
    if (_report == null) return SizedBox.shrink();

    final distributions = _report!.moodDistribution;

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0420\u0430\u0441\u043F\u0440\u0435\u0434\u0435\u043B\u0435\u043D\u0438\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F',
            style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          AppSize.gapH(16),
          ...distributions.where((d) => d.count > 0).map((d) => Padding(
            padding: AppSize.paddingOnly(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.emoji, style: TextStyle(fontSize: AppSize.s(14))),
                    AppSize.gapW(6),
                    Text(d.label, style: TextStyle(fontSize: AppSize.s(12), color: AppColors.foreground, fontWeight: FontWeight.w500)),
                    Spacer(),
                    Text('${d.count} (${d.percent.toStringAsFixed(0)}%)', style: TextStyle(fontSize: AppSize.s(11), color: AppColors.mutedForeground)),
                  ],
                ),
                AppSize.gapH(6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: AppSize.radius(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: d.percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(d.colorValue),
                        borderRadius: AppSize.radius(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    if (_report == null || _report!.insights.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u0418\u043D\u0441\u0430\u0439\u0442\u044B',
          style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
        ),
        AppSize.gapH(12),
        Container(
          padding: AppSize.padding(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 140, 66, 0.08),
                Color.fromRGBO(255, 173, 31, 0.04),
              ],
            ),
            borderRadius: AppSize.radius(16),
            border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: _report!.insights.map((insight) => Padding(
              padding: AppSize.paddingOnly(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F4A1}', style: TextStyle(fontSize: AppSize.s(18))),
                  AppSize.gapW(10),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    if (_report == null) return SizedBox.shrink();

    final a = _report!.activity;

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0410\u043A\u0442\u0438\u0432\u043D\u043E\u0441\u0442\u044C',
            style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          AppSize.gapH(16),
          _buildActivityBar('\u0417\u0430\u043F\u0438\u0441\u0438 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F', a.moodRecords, 30, AppColors.citrusOrange),
          AppSize.gapH(12),
          _buildActivityBar('\u0421\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u044F \u0432 \u0447\u0430\u0442\u0435', a.chatMessages, 30, AppColors.citrusAmber),
          AppSize.gapH(12),
          _buildActivityBar('\u0423\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F', a.exercises, 30, AppColors.moodGood),
          AppSize.gapH(12),
          _buildActivityBar('\u0422\u0435\u0441\u0442\u044B', a.tests, 30, AppColors.moodVeryBad),
          AppSize.gapH(12),
          _buildActivityBar('\u0417\u0430\u043F\u0438\u0441\u0438 \u0441\u043D\u0430', a.sleepRecords, 30, AppColors.citrusPurple),
        ],
      ),
    );
  }

  Widget _buildSleepSection() {
    if (_report == null) return SizedBox.shrink();

    final m = _report!.metrics;
    if (m.sleepRecords == 0) return SizedBox.shrink();

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('\u{1F4A4}', style: TextStyle(fontSize: AppSize.s(18))),
              AppSize.gapW(8),
              Text(
                '\u0410\u043D\u0430\u043B\u0438\u0437 \u0441\u043D\u0430',
                style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600, color: AppColors.foreground),
              ),
            ],
          ),
          AppSize.gapH(16),
          Row(
            children: [
              Expanded(
                child: _buildSleepMetricCard(
                  '\u0417\u0430\u043F\u0438\u0441\u0435\u0439',
                  m.sleepRecords.toString(),
                  Icons.bookmark_outline,
                  AppColors.citrusPurple,
                ),
              ),
              AppSize.gapW(12),
              Expanded(
                child: _buildSleepMetricCard(
                  '\u0421\u0440\u0435\u0434\u043D\u0435\u0435 \u0432\u0440\u0435\u043C\u044F',
                  '${m.averageSleepHours.toStringAsFixed(1)} \u0447',
                  Icons.access_time,
                  AppColors.citrusAmber,
                ),
              ),
            ],
          ),
          AppSize.gapH(12),
          Row(
            children: [
              Expanded(
                child: _buildSleepMetricCard(
                  '\u041A\u0430\u0447\u0435\u0441\u0442\u0432\u043E',
                  '${m.sleepQuality.toStringAsFixed(1)}/5',
                  Icons.star_outline,
                  AppColors.moodGood,
                ),
              ),
              AppSize.gapW(12),
              Expanded(
                child: _buildSleepMetricCard(
                  '\u041E\u0446\u0435\u043D\u043A\u0430',
                  m.averageSleepHours >= 7 && m.sleepQuality >= 4 ? '\u041E\u0442\u043B\u0438\u0447\u043D\u043E' :
                  m.averageSleepHours >= 6 ? '\u041D\u043E\u0440\u043C\u0430' : '\u041C\u0430\u043B\u043E\u0432\u0430\u0442\u043E',
                  Icons.check_circle_outline,
                  m.averageSleepHours >= 7 && m.sleepQuality >= 4 ? AppColors.moodGood :
                  m.averageSleepHours >= 6 ? AppColors.citrusOrange : AppColors.moodVeryBad,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppSize.radius(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          AppSize.gapH(6),
          Text(
            value,
            style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          AppSize.gapH(2),
          Text(
            label,
            style: TextStyle(fontSize: AppSize.s(10), color: AppColors.dimForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(String label, int value, int maxValue, Color color) {
    final percent = maxValue > 0 ? (value / maxValue).toDouble().clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
            Spacer(),
            Text(value.toString(), style: TextStyle(fontSize: AppSize.s(14), fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        AppSize.gapH(6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: AppSize.radius(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppSize.radius(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildExportButton(icon: Icons.picture_as_pdf, label: 'PDF', onTap: _generatePdfReport),
        ),
      ],
    );
  }

  Widget _buildExportButton({required IconData icon, required String label, required VoidCallback onTap, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: AppSize.paddingH(0, 12),
        decoration: BoxDecoration(
          color: isLoading ? AppColors.surface3 : AppColors.surface1,
          borderRadius: AppSize.radius(12),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.citrusOrange, size: 18),
                  AppSize.gapW(8),
                  Text(label, style: TextStyle(fontSize: AppSize.s(13), fontWeight: FontWeight.w600, color: AppColors.foreground)),
                ],
              ),
      ),
    );
  }
}

class _DistributionData {
  final String emoji;
  final String label;
  final int count;
  final int percent;
  final Color color;

  _DistributionData({required this.emoji, required this.label, required this.count, required this.percent, required this.color});
}

class _InsightData {
  final String icon;
  final String text;

  _InsightData({required this.icon, required this.text});
}

class _ActivityData {
  final String label;
  final int value;
  final Color color;

  _ActivityData({required this.label, required this.value, required this.color});
}
