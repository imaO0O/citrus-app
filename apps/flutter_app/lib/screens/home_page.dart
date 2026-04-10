import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/dashboard_bloc.dart';
import 'models/mood.dart';
import 'widgets/citrus_wheel.dart';
import 'widgets/stats_strip.dart';
import 'widgets/quick_links.dart';
import 'widgets/mood_log.dart';
import 'widgets/daily_quote.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToExercises;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToDiary;
  final VoidCallback? onNavigateToSleep;

  const HomePage({
    super.key,
    this.onNavigateToExercises,
    this.onNavigateToChat,
    this.onNavigateToDiary,
    this.onNavigateToSleep,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(DashboardLoad());
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF8C42),
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
              color: const Color(0xFFFF8C42),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8A8298),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Как твоё состояние?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEDE8E0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Нажми на дольку цитруса, чтобы отметить настроение',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5A5468),
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
                                key: ValueKey('mood_${state.selectedMoodId}'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 255, 255, 0.06),
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
                                child: const Text(
                                  '6 уровней настроения · нажми на дольку',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A5468),
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
                    ),

                    const SizedBox(height: 16),

                    // ─── Today's Mood Log ───
                    MoodLog(entries: state.todayLog),

                    // ─── Daily Quote ───
                    const DailyQuote(),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}
