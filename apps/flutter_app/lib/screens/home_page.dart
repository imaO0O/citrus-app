import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/dashboard_bloc.dart';
import '../core/theme/app_colors.dart';
import '../services/affirmations_service.dart';
import 'models/mood.dart';
import 'widgets/citrus_wheel.dart';
import 'widgets/stats_strip.dart';
import 'widgets/quick_links.dart';
import 'widgets/mood_log.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToExercises;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToDiary;
  final VoidCallback? onNavigateToSleep;
  final VoidCallback? onNavigateToTests;

  const HomePage({
    super.key,
    this.onNavigateToExercises,
    this.onNavigateToChat,
    this.onNavigateToDiary,
    this.onNavigateToSleep,
    this.onNavigateToTests,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AffirmationsService _affirmationsService = AffirmationsService();
  Affirmation? _dailyAffirmation;
  bool _isLoadingAffirmation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(DashboardLoad());
      _loadDailyAffirmation();
    });
  }

  Future<void> _loadDailyAffirmation() async {
    final affirmations = await _affirmationsService.getCachedAffirmations();
    if (affirmations.isNotEmpty && mounted) {
      // Выбираем одну случайную аффирмацию
      final index = DateTime.now().day % affirmations.length;
      setState(() {
        _dailyAffirmation = affirmations[index];
        _isLoadingAffirmation = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    Intl.defaultLocale = 'ru_RU';
    final day = DateFormat('d').format(date);
    final month = DateFormat('LLLL').format(date);
    final weekday = DateFormat('EEEE').format(date);
    return '$weekday, $day $month';
  }

  void _onMoodSelected(int moodId) {
    HapticFeedback.mediumImpact();

    context.read<DashboardBloc>().add(
      MoodSelected(moodId: moodId, timestamp: DateTime.now()),
    );
  }

  Widget _buildDailyAffirmation() {
    if (_isLoadingAffirmation || _dailyAffirmation == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _dailyAffirmation!.color.withOpacity(0.15),
              _dailyAffirmation!.color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: _dailyAffirmation!.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: _dailyAffirmation!.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Аффирмация дня',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _dailyAffirmation!.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _dailyAffirmation!.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"${_dailyAffirmation!.text}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.foreground,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.citrusOrange,
                ),
              );
            }

            if (state is! DashboardLoaded) {
              return const Center(child: Text('Загрузка...'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(MoodLogRefresh());
              },
              color: AppColors.citrusOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Greeting ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Как твоё состояние?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Нажми на дольку цитруса, чтобы отметить настроение',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.dimForeground,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Citrus Wheel ───
                    const SizedBox(height: 8),
                    Center(
                      child: CitrusWheel(
                        selectedMoodId: state.selectedMoodId,
                        onMoodSelected: _onMoodSelected,
                      ),
                    ),

                    // ─── Selected mood label ───
                    const SizedBox(height: 8),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: state.selectedMoodId != null
                            ? Container(
                                key: ValueKey('mood_${state.selectedMoodId}_${state.selectionKey}'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.foreground.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${Mood.all.firstWhere((m) => m.id == state.selectedMoodId).emoji} ${Mood.all.firstWhere((m) => m.id == state.selectedMoodId).label} — записано',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Mood.all
                                        .firstWhere((m) => m.id == state.selectedMoodId)
                                        .color,
                                  ),
                                ),
                              )
                            : Container(
                                key: const ValueKey('mood_hint'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '6 уровней настроения · нажми на дольку',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.dimForeground,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Stats Strip ───
                    StatsStrip(
                      streakDays: state.streakDays,
                      goodDaysPercent: state.goodDaysPercent,
                      sleepHours: state.sleepHours,
                    ),

                    const SizedBox(height: 16),

                    // ─── Quick Links ───
                    QuickLinks(
                      onExerciseTap: widget.onNavigateToExercises,
                      onChatTap: widget.onNavigateToChat,
                      onDiaryTap: widget.onNavigateToDiary,
                      onSleepTap: widget.onNavigateToSleep,
                      onTestsTap: widget.onNavigateToTests,
                    ),

                    const SizedBox(height: 16),

                    // ─── Today's Mood Log ───
                    MoodLog(entries: state.todayLog),

                    // ─── Daily Affirmation ───
                    _buildDailyAffirmation(),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}
