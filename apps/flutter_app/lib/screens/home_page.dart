import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/dashboard_bloc.dart';
import '../core/theme/app_colors.dart';
import '../core/repository/mood_repository.dart';
import '../core/services/storage_service.dart';
import '../services/affirmations_service.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'help_screen.dart';
import 'models/mood.dart';
import 'widgets/citrus_wheel.dart';
import 'widgets/stats_strip.dart';
import 'widgets/quick_links.dart';
import 'widgets/mood_log.dart';
import '../core/utils/app_size.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToExercises;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToDiary;
  final VoidCallback? onNavigateToSleep;
  final VoidCallback? onNavigateToTests;

  HomePage({
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final AffirmationsService _affirmationsService = AffirmationsService();
  Affirmation? _dailyAffirmation;
  bool _isLoadingAffirmation = true;
  late final AnimationController _anim;
  bool _revealed = false;
  bool _showWarning = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(DashboardLoad());
      _loadDailyAffirmation();
      _checkEarlyWarning();
    });
  }

  /// Раннее предупреждение: если за последние дни много «плохих» дней — мягко
  /// предложить заботу. Показывается не чаще раза в день (после закрытия).
  Future<void> _checkEarlyWarning() async {
    try {
      final moodRepo = context.read<MoodRepository>();
      final today = DateTime.now();
      final dKey = 'ew_dismissed_${today.year}-${today.month}-${today.day}';
      final dismissed = await StorageService().getString(dKey);
      if (dismissed == 'true') return;

      final from = today.subtract(const Duration(days: 6));
      final map = await moodRepo.getAverageMoodByDay(startDate: from, endDate: today);
      if (map.length < 3) return; // мало данных — не тревожим

      // moodId: 0 — лучше, 5 — хуже. «Плохой» день: средний >= 3.
      final badDays = map.values.where((v) => v >= 3.0).length;
      if (badDays >= 3 && mounted) setState(() => _showWarning = true);
    } catch (_) {}
  }

  Future<void> _dismissWarning() async {
    final t = DateTime.now();
    await StorageService().setString('ew_dismissed_${t.year}-${t.month}-${t.day}', 'true');
    if (mounted) setState(() => _showWarning = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAffirmation() async {
    final affirmations = await _affirmationsService.getCachedAffirmations();
    if (affirmations.isNotEmpty && mounted) {
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Доброй ночи';
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 6) return '🌙';
    if (h < 12) return '☀️';
    if (h < 18) return '🍊';
    return '🌆';
  }

  void _onMoodSelected(int moodId) {
    HapticFeedback.mediumImpact();
    context.read<DashboardBloc>().add(
          MoodSelected(moodId: moodId, timestamp: DateTime.now()),
        );
  }

  /// Плавное «проявление» секции со сдвигом снизу (staggered).
  Widget _reveal(int i, Widget child) {
    final start = (0.06 * i).clamp(0.0, 0.6).toDouble();
    final end = (start + 0.5).clamp(0.0, 1.0).toDouble();
    final anim = CurvedAnimation(parent: _anim, curve: Interval(start, end, curve: Curves.easeOut));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  // ─────────────────────────── Header ───────────────────────────

  Widget _buildHeader(String name, String? avatarUrl) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.citrusOrange.withValues(alpha: 0.14), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(fontSize: AppSize.s(12), fontWeight: FontWeight.w500, color: AppColors.mutedForeground),
                ),
                AppSize.gapH(5),
                Text(
                  '${_greeting()}, $name ${_greetingEmoji()}',
                  style: TextStyle(fontSize: AppSize.s(23), fontWeight: FontWeight.w800, color: AppColors.foreground),
                ),
              ],
            ),
          ),
          AppSize.gapW(12),
          _avatar(name, avatarUrl),
        ],
      ),
    );
  }

  Widget _avatar(String name, String? avatarUrl) {
    final size = AppSize.s(46);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(name, size),
        ),
      );
    }
    return _avatarFallback(name, size);
  }

  Widget _avatarFallback(String name, double size) {
    final letter = name.isNotEmpty && name != 'друг' ? name[0].toUpperCase() : '🍊';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
        boxShadow: [BoxShadow(color: AppColors.citrusOrange.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 1)],
      ),
      child: Center(child: Text(letter, style: TextStyle(color: Colors.white, fontSize: AppSize.s(20), fontWeight: FontWeight.w700))),
    );
  }

  // ─────────────────────── Wheel section ────────────────────────

  Widget _buildWheelSection(DashboardLoaded state, Color moodColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSize.paddingH(20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Как ты себя чувствуешь?',
                style: TextStyle(fontSize: AppSize.s(18), fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
              AppSize.gapH(3),
              Text(
                'Нажми на дольку цитруса, чтобы отметить настроение',
                style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground),
              ),
            ],
          ),
        ),
        AppSize.gapH(10),
        // Колесо с мягким свечением в цвете выбранного настроения
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: moodColor.withValues(alpha: 0.18), blurRadius: 50, spreadRadius: 6)],
            ),
            child: CitrusWheel(
              selectedMoodId: state.selectedMoodId,
              onMoodSelected: _onMoodSelected,
            ),
          ),
        ),
        AppSize.gapH(10),
        Center(child: _buildMoodLabel(state)),
      ],
    );
  }

  Widget _buildMoodLabel(DashboardLoaded state) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state.selectedMoodId != null
          ? Container(
              key: ValueKey('mood_${state.selectedMoodId}_${state.selectionKey}'),
              padding: AppSize.paddingH(12, 4),
              decoration: BoxDecoration(
                color: AppColors.foreground.withValues(alpha: 0.06),
                borderRadius: AppSize.radius(20),
              ),
              child: Text(
                '${Mood.all.firstWhere((m) => m.id == state.selectedMoodId).emoji} ${Mood.all.firstWhere((m) => m.id == state.selectedMoodId).label} — записано',
                style: TextStyle(
                  fontSize: AppSize.s(12),
                  fontWeight: FontWeight.w600,
                  color: Mood.all.firstWhere((m) => m.id == state.selectedMoodId).color,
                ),
              ),
            )
          : Container(
              key: const ValueKey('mood_hint'),
              padding: AppSize.paddingH(12, 4),
              child: Text(
                '6 уровней настроения · нажми на дольку',
                style: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground),
              ),
            ),
    );
  }

  // ─────────────────────── Early warning ────────────────────────

  Widget _buildEarlyWarning() {
    final color = AppColors.citrusAmber;
    Widget btn(IconData icon, String label, VoidCallback? onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: AppSize.paddingH(0, 10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: AppSize.radius(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: AppSize.s(15), color: color),
                AppSize.gapW(5),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: AppSize.s(12), fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        );
    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: Container(
        padding: AppSize.padding(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSize.radius(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('🤍', style: TextStyle(fontSize: AppSize.s(18))),
            AppSize.gapW(8),
            Expanded(child: Text('Заботливое напоминание', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w700))),
            GestureDetector(onTap: _dismissWarning, child: Icon(Icons.close, size: AppSize.s(18), color: AppColors.dimForeground)),
          ]),
          AppSize.gapH(6),
          Text('Похоже, последние дни были непростыми. Удели пару минут себе 🤍', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12), height: 1.4)),
          AppSize.gapH(10),
          Row(children: [
            btn(Icons.self_improvement, 'Подышать', widget.onNavigateToExercises),
            AppSize.gapW(8),
            btn(Icons.chat_bubble_outline, 'Поговорить', widget.onNavigateToChat),
            AppSize.gapW(8),
            btn(Icons.support_agent, 'Помощь', () => Navigator.push(context, MaterialPageRoute(builder: (_) => HelpScreen()))),
          ]),
        ]),
      ),
    );
  }

  // ───────────────────── Recommendation card ────────────────────

  Widget _buildRecommendation(DashboardLoaded state) {
    IconData icon;
    String title;
    String subtitle;
    Color color;
    VoidCallback? onTap;

    if (state.todayLog.isEmpty) {
      icon = Icons.touch_app_outlined;
      color = AppColors.citrusOrange;
      title = 'Отметь настроение';
      subtitle = 'Нажми на дольку цитруса выше — это займёт секунду';
      onTap = null;
    } else if (state.selectedMoodId != null && state.selectedMoodId! >= 3) {
      icon = Icons.self_improvement;
      color = AppColors.citrusGreen;
      title = 'Сложный момент?';
      subtitle = 'Подыши пару минут — поможет успокоиться';
      onTap = widget.onNavigateToExercises;
    } else if (state.streakDays == 0) {
      icon = Icons.local_fire_department;
      color = AppColors.citrusAmber;
      title = 'Начни свою серию';
      subtitle = 'Отмечай настроение каждый день — копи стрик';
      onTap = null;
    } else if (DateTime.now().day.isEven) {
      icon = Icons.edit_note;
      color = AppColors.citrusOrange;
      title = 'Запиши мысль';
      subtitle = 'Пара строк в дневнике помогают разгрузить голову';
      onTap = widget.onNavigateToDiary;
    } else {
      icon = Icons.fact_check_outlined;
      color = AppColors.citrusPurple;
      title = 'Короткий тест';
      subtitle = 'Загляни, как ты себя чувствуешь — это быстро';
      onTap = widget.onNavigateToTests;
    }

    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSize.padding(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppSize.radius(18),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: AppSize.s(42),
                height: AppSize.s(42),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppSize.radius(12)),
                child: Icon(icon, color: color, size: AppSize.s(22)),
              ),
              AppSize.gapW(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: AppSize.s(15), fontWeight: FontWeight.w700, color: AppColors.foreground)),
                    AppSize.gapH(2),
                    Text(subtitle, style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground, height: 1.35)),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: AppColors.dimForeground, size: AppSize.s(22)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Daily affirmation ────────────────────

  Widget _buildDailyAffirmation() {
    if (_isLoadingAffirmation || _dailyAffirmation == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: AppSize.paddingH(20, 0),
      child: Container(
        width: double.infinity,
        padding: AppSize.padding(20),
        decoration: BoxDecoration(
          borderRadius: AppSize.radius(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _dailyAffirmation!.color.withValues(alpha: 0.15),
              _dailyAffirmation!.color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: _dailyAffirmation!.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote, color: _dailyAffirmation!.color, size: 20),
                AppSize.gapW(8),
                Text(
                  'Аффирмация дня',
                  style: TextStyle(fontSize: AppSize.s(12), fontWeight: FontWeight.w600, color: _dailyAffirmation!.color),
                ),
              ],
            ),
            AppSize.gapH(12),
            Row(
              children: [
                Text(_dailyAffirmation!.emoji, style: TextStyle(fontSize: AppSize.s(32))),
                AppSize.gapW(12),
                Expanded(
                  child: Text(
                    '"${_dailyAffirmation!.text}"',
                    style: TextStyle(
                      fontSize: AppSize.s(16),
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

  Widget _sectionTitle(String t) => Padding(
        padding: AppSize.paddingH(20, 0),
        child: Text(t, style: TextStyle(fontSize: AppSize.s(15), fontWeight: FontWeight.w700, color: AppColors.foreground)),
      );

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String name = 'друг';
    String? avatarUrl;
    if (authState is AuthAuthenticated) {
      final n = authState.user.name?.trim();
      if (n != null && n.isNotEmpty) name = n.split(' ').first;
      avatarUrl = authState.user.avatarUrl;
    }

    return Scaffold(
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return Center(child: CircularProgressIndicator(color: AppColors.citrusOrange));
          }
          if (state is! DashboardLoaded) {
            return Center(child: Text('Загрузка...'));
          }

          if (!_revealed) {
            _revealed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _anim.forward();
            });
          }

          final moodColor = state.selectedMoodId != null
              ? Mood.all.firstWhere((m) => m.id == state.selectedMoodId, orElse: () => Mood.all.first).color
              : AppColors.citrusOrange;

          return RefreshIndicator(
            onRefresh: () async => context.read<DashboardBloc>().add(MoodLogRefresh()),
            color: AppColors.citrusOrange,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSize.paddingOnly(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(0, _buildHeader(name, avatarUrl)),
                  _reveal(1, _buildWheelSection(state, moodColor)),
                  if (_showWarning) ...[
                    AppSize.gapH(16),
                    _buildEarlyWarning(),
                  ],
                  AppSize.gapH(20),
                  _reveal(2, _buildRecommendation(state)),
                  AppSize.gapH(16),
                  _reveal(3, StatsStrip(
                    streakDays: state.streakDays,
                    goodDaysPercent: state.goodDaysPercent,
                    sleepHours: state.sleepHours,
                  )),
                  AppSize.gapH(16),
                  _reveal(4, _buildDailyAffirmation()),
                  AppSize.gapH(16),
                  _reveal(5, _sectionTitle('Быстрый доступ')),
                  AppSize.gapH(10),
                  _reveal(6, QuickLinks(
                    onExerciseTap: widget.onNavigateToExercises,
                    onChatTap: widget.onNavigateToChat,
                    onDiaryTap: widget.onNavigateToDiary,
                    onSleepTap: widget.onNavigateToSleep,
                    onTestsTap: widget.onNavigateToTests,
                  )),
                  AppSize.gapH(16),
                  _reveal(7, MoodLog(entries: state.todayLog)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
