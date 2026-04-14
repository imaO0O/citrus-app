import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../core/theme/app_colors.dart';
import '../services/pdf_report_service.dart';
import '../models/analytics_report.dart';
import '../models/sleep_record.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/sleep_repository.dart';
import '../core/services/storage_service.dart';
import '../core/api/test_api_service.dart';
import '../core/services/exercise_tracker_service.dart';
import '../core/services/test_tracking_service.dart';
import '../core/config/api_config.dart';
import '../services/stats_api_client.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['\u041D\u0435\u0434\u0435\u043B\u044F', '\u041C\u0435\u0441\u044F\u0446', '3 \u043C\u0435\u0441', '\u0413\u043E\u0434'];
  bool _isGeneratingPdf = false;
  bool _isLoading = true;
  AnalyticsReport? _report;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  /// Публичный метод для принудительного обновления данных (вызывается при навигации)
  void refreshData() {
    // Всегда обновляем данные, даже если ещё не инициализировано
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
    setState(() => _isLoading = true);

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
        debugPrint('Analytics: NOT AUTHORIZED - using sample data');
        // Если не авторизован, используем демо-данные
        setState(() {
          _report = _createSampleReport();
          _isLoading = false;
          _initialized = true;
        });
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
      final goodDaysPercent = await moodRepo.getGoodDaysPercentage();
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

      setState(() {
        _report = AnalyticsReport(
          period: ReportPeriod(
            label: _periods[_selectedPeriod],
            startDate: startDate,
            endDate: now,
          ),
          metrics: ReportMetrics(
            totalDays: daysBack,
            goodDaysPercent: goodDaysPercent,
            improvementPercent: 0, // Требуется сравнение с предыдущим периодом
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
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() {
        _report = _createSampleReport();
        _isLoading = false;
        _initialized = true;
      });
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

  Color _getMoodBarColor(double value) {
    if (value >= 5) return AppColors.moodExcellent;
    if (value >= 4) return AppColors.moodGood;
    if (value >= 3) return AppColors.citrusOrange;
    if (value >= 2) return AppColors.moodAnxious;
    return AppColors.moodVeryBad;
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

  /// Создать тестовый отчёт (заглушка - заменить данными из репозиториев)
  AnalyticsReport _createSampleReport() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));

    return AnalyticsReport(
      period: ReportPeriod(
        label: 'Неделя',
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 13),
      ),
      metrics: ReportMetrics(
        totalDays: 30,
        goodDaysPercent: 71,
        improvementPercent: 15,
        streakDays: 7,
        averageMood: 4.1,
        averageSleepHours: 7.5,
        sleepQuality: 4.2,
        sleepRecords: 7,
      ),
      moodByDay: [
        MoodDayData(dayName: 'Пн', value: 4.2, date: DateTime(2026, 4, 6)),
        MoodDayData(dayName: 'Вт', value: 4.8, date: DateTime(2026, 4, 7)),
        MoodDayData(dayName: 'Ср', value: 3.5, date: DateTime(2026, 4, 8)),
        MoodDayData(dayName: 'Чт', value: 4.0, date: DateTime(2026, 4, 9)),
        MoodDayData(dayName: 'Пт', value: 5.0, date: DateTime(2026, 4, 10)),
        MoodDayData(dayName: 'Сб', value: 2.8, date: DateTime(2026, 4, 11)),
        MoodDayData(dayName: 'Вс', value: 4.5, date: DateTime(2026, 4, 12)),
      ],
      moodDistribution: [
        MoodDistribution(emoji: '😄', label: 'Отлично', count: 9, percent: 30, colorValue: 0xFF4ADE80),
        MoodDistribution(emoji: '🙂', label: 'Хорошо', count: 12, percent: 40, colorValue: 0xFF86EFAC),
        MoodDistribution(emoji: '😐', label: 'Нормально', count: 6, percent: 20, colorValue: 0xFFFF8C42),
        MoodDistribution(emoji: '😟', label: 'Тревожно', count: 3, percent: 10, colorValue: 0xFFEF4444),
      ],
      insights: [
        'Ваше настроение лучше всего в середине недели. Планируйте сложные задачи на вторник-среду.',
        'Дни с хорошим сном на 40% чаще имеют положительное настроение.',
        'После дней с физической активностью настроение улучшается на 25%.',
        'Регулярные упражнения на дыхание снижают тревожность на 30%.',
      ],
      activity: ActivityStats(
        moodRecords: 24,
        chatMessages: 18,
        exercises: 12,
        tests: 5,
        sleepRecords: 7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    SizedBox(height: 16),
                    Text(
                      'Загрузка аналитики...',
                      style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              SizedBox(height: 16),
                              _buildPeriodSelector(),
                              SizedBox(height: 20),
                              _buildOverviewCards(),
                              SizedBox(height: 20),
                              _buildMoodChart(),
                              SizedBox(height: 20),
                              _buildMoodDistribution(),
                              SizedBox(height: 20),
                              _buildInsights(),
                              SizedBox(height: 20),
                              _buildSleepSection(),
                              SizedBox(height: 20),
                              _buildActivitySection(),
                              SizedBox(height: 20),
                              _buildExportButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\u0410\u043D\u0430\u043B\u0438\u0442\u0438\u043A\u0430',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
            ),
            SizedBox(height: 4),
            Text(
              '\u041E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0439\u0442\u0435 \u0441\u0432\u043E\u0439 \u043F\u0440\u043E\u0433\u0440\u0435\u0441\u0441',
              style: TextStyle(fontSize: 13, color: AppColors.dimForeground),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.download_outlined, color: AppColors.citrusOrange, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = index == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = index);
                _loadReportData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildOverviewCards() {
    if (_report == null) return const SizedBox.shrink();

    final m = _report!.metrics;
    final cards = [
      {'value': m.totalDays.toString(), 'label': '\u0414\u043D\u0435\u0439'},
      {'value': '${m.goodDaysPercent.toStringAsFixed(0)}%', 'label': '\u0425\u043E\u0440\u043E\u0448\u0438\u0445 \u0434\u043D\u0435\u0439'},
      {'value': '+${m.improvementPercent.toStringAsFixed(0)}%', 'label': '\u0423\u043B\u0443\u0447\u0448\u0435\u043D\u0438\u0435'},
      {'value': m.streakDays.toString(), 'label': '\u0421\u0435\u0440\u0438\u044F \u0434\u043D\u0435\u0439'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                card['value'] as String,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
              SizedBox(height: 4),
              Text(
                card['label'] as String,
                style: TextStyle(fontSize: 10, color: AppColors.dimForeground),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodChart() {
    if (_report == null) return const SizedBox.shrink();

    final moodByDay = _report!.moodByDay;
    
    if (moodByDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Center(
          child: Text(
            'Нет данных о настроении за выбранный период',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
          ),
        ),
      );
    }

    final days = moodByDay.map((d) => d.dayName).toList();
    final values = moodByDay.map((d) => d.value).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0413\u0440\u0430\u0444\u0438\u043A \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F (${moodByDay.length} \u0434\u043D\u0435\u0439)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final value = values[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 36,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: value > 0 ? 110 * (value / 5) : 4,
                            decoration: BoxDecoration(
                              color: value > 0 ? _getMoodBarColor(value) : AppColors.surface3,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            days[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: AppColors.dimForeground),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution() {
    if (_report == null) return const SizedBox.shrink();

    final distributions = _report!.moodDistribution;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0420\u0430\u0441\u043F\u0440\u0435\u0434\u0435\u043B\u0435\u043D\u0438\u0435 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          SizedBox(height: 16),
          ...distributions.where((d) => d.count > 0).map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.emoji, style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(d.label, style: TextStyle(fontSize: 12, color: AppColors.foreground, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('${d.count} (${d.percent.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
                SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: d.percent / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(d.colorValue),
                        borderRadius: BorderRadius.circular(5),
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
    if (_report == null || _report!.insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u0418\u043D\u0441\u0430\u0439\u0442\u044B',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 140, 66, 0.08),
                Color.fromRGBO(255, 173, 31, 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.citrusOrange.withOpacity(0.1)),
          ),
          child: Column(
            children: _report!.insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u{1F4A1}', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.4),
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
    if (_report == null) return const SizedBox.shrink();

    final a = _report!.activity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0410\u043A\u0442\u0438\u0432\u043D\u043E\u0441\u0442\u044C',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          ),
          SizedBox(height: 16),
          _buildActivityBar('\u0417\u0430\u043F\u0438\u0441\u0438 \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u044F', a.moodRecords, 30, AppColors.citrusOrange),
          SizedBox(height: 12),
          _buildActivityBar('\u0421\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u044F \u0432 \u0447\u0430\u0442\u0435', a.chatMessages, 30, AppColors.citrusAmber),
          SizedBox(height: 12),
          _buildActivityBar('\u0423\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F', a.exercises, 30, AppColors.moodGood),
          SizedBox(height: 12),
          _buildActivityBar('\u0422\u0435\u0441\u0442\u044B', a.tests, 30, AppColors.moodVeryBad),
          SizedBox(height: 12),
          _buildActivityBar('\u0417\u0430\u043F\u0438\u0441\u0438 \u0441\u043D\u0430', a.sleepRecords, 30, AppColors.citrusPurple),
        ],
      ),
    );
  }

  Widget _buildSleepSection() {
    if (_report == null) return const SizedBox.shrink();

    final m = _report!.metrics;
    if (m.sleepRecords == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('\u{1F4A4}', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                '\u0410\u043D\u0430\u043B\u0438\u0437 \u0441\u043D\u0430',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
              ),
            ],
          ),
          SizedBox(height: 16),
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
              SizedBox(width: 12),
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
          SizedBox(height: 12),
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
              SizedBox(width: 12),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppColors.dimForeground),
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
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isLoading ? AppColors.surface3 : AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
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
                  SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground)),
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

  const _DistributionData({required this.emoji, required this.label, required this.count, required this.percent, required this.color});
}

class _InsightData {
  final String icon;
  final String text;

  const _InsightData({required this.icon, required this.text});
}

class _ActivityData {
  final String label;
  final int value;
  final Color color;

  const _ActivityData({required this.label, required this.value, required this.color});
}
