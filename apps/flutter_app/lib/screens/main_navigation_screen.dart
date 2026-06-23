import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/theme_service.dart';
import '../screens/home_page.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/affirmations_screen.dart';
import '../screens/photo_gallery_screen.dart';
import '../screens/toy_screen.dart';
import '../screens/sleep_tracker_screen.dart';
import '../screens/tests_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/insights/weekly_insights_screen.dart';
import '../screens/tree/citrus_tree_screen.dart';
import '../screens/student/student_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/legal/consent_screen.dart';
import '../screens/lock/pin_screen.dart';
import '../screens/emergency_modal.dart';
import '../core/services/storage_service.dart';
import '../core/services/pin_service.dart';
import '../core/services/offline_queue_service.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/diary_repository.dart';
import '../core/repository/sleep_repository.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../features/diary/bloc/diary_bloc.dart';
import '../features/sleep/bloc/sleep_bloc.dart';
import '../features/articles/pages/articles_page.dart';
import '../features/articles/bloc/article_bloc.dart';
import '../core/utils/app_size.dart';

class MainNavigationScreen extends StatefulWidget {
  MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _showMenu = false;
  // Блокировка PIN-кодом
  bool _pinEnabled = false;
  bool _pinChecked = false;
  bool _unlocked = false;
  bool _showEmergency = false;

  // 0-3: main nav screens, 4+: feature screens
  static const _mainScreenCount = 4;

  // Ключ для AnalyticsScreen, чтобы вызывать refresh при навигации
  final GlobalKey _analyticsKey = GlobalKey();

  /// Экраны строятся заново на каждый build(), а не кэшируются в поле — иначе при
  /// смене темы IndexedStack получает те же экземпляры виджетов, и Flutter пропускает
  /// их перестроение (статические AppColors остаются в старой теме). State экранов
  /// при этом сохраняется, т.к. их тип и позиция в списке не меняются.
  List<Widget> _buildScreens() {
    return [
      HomePage(                 // 0 — homepage
        onNavigateToExercises: () => _setIndex(9),
        onNavigateToChat: () => _setIndex(2),
        onNavigateToDiary: () => _setIndex(3),
        onNavigateToSleep: () => _setIndex(7),
        onNavigateToTests: () => _setIndex(8),
        onNavigateToTree: () => _setIndex(15),
      ),
      CalendarScreen(),            // 1
      ChatScreen(),                // 2
      DiaryScreen(),               // 3
      AffirmationsScreen(),        // 4
      PhotoGalleryScreen(),        // 5
      ToyScreen(),                 // 6
      SleepTrackerScreen(),        // 7
      TestsScreen(),               // 8
      ExercisesScreen(),           // 9
      AnalyticsScreen(key: _analyticsKey),           // 10
      SettingsScreen(),            // 11
      ArticlesPage(showBackButton: false),  // 12
      CoursesListScreen(),         // 13
      WeeklyInsightsScreen(),      // 14
      CitrusTreeScreen(),          // 15
      StudentScreen(),             // 16
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLock();

    // Инициализация BLoC при старте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is AuthAuthenticated) {
          debugPrint('MainNav: init — пользователь уже авторизован, userId=${authState.user.id}');
          context.read<DashboardBloc>().updateUserId(authState.user.id, token: authState.user.token);
          context.read<DiaryBloc>().updateUserId(authState.user.id, token: authState.user.token);
          context.read<SleepBloc>().updateUserId(authState.user.id, token: authState.user.token);
          context.read<ArticleBloc>().setToken(authState.user.token);
        }
      } catch (e) {
        debugPrint('MainNav: ошибка init BLoC: $e');
      }
      _maybeShowOnboarding();
      _flushOutbox();
    });
  }

  /// До-отправка офлайн-очереди (настроение/дневник/сон), накопленной без сети.
  /// Только для авторизованного пользователя (иначе запросы уйдут без токена).
  void _flushOutbox() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    try {
      final mood = context.read<MoodRepository>();
      final diary = context.read<DiaryRepository>();
      final sleep = context.read<SleepRepository>();
      OfflineQueueService.instance.flush({
        'mood': mood.replayCreate,
        'diary': diary.replayCreate,
        'sleep': sleep.replayCreate,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Перезапираем при возврате из фона
      if (_pinEnabled) setState(() => _unlocked = false);
      // И пробуем дотолкнуть офлайн-очередь (вдруг сеть вернулась)
      _flushOutbox();
    }
  }

  Future<void> _loadLock() async {
    final en = await PinService().isEnabled();
    if (mounted) setState(() { _pinEnabled = en; _pinChecked = true; });
  }

  /// Первый запуск: сначала обязательное согласие (политика), затем короткий тур.
  Future<void> _maybeShowOnboarding() async {
    try {
      // Явное согласие на обработку данных — блокирующее (ConsentScreen не
      // закрывается, пока пользователь не примет политику).
      final consent = await StorageService().getString(ConsentScreen.flagKey);
      if (consent != 'true' && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ConsentScreen()),
        );
      }

      final seen = await StorageService().getString('onboarding_seen');
      if (seen == 'true' || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => const OnboardingScreen()),
      );
      await StorageService().setString('onboarding_seen', 'true');
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _allFeatures = [
    {'path': '4',  'label': 'Аффирмации', 'icon': Icons.auto_awesome,           'desc': 'Позитивные установки', 'color': const Color(0xFF9C6ADE)},
    {'path': '5',  'label': 'Галерея',    'icon': Icons.photo_library_outlined, 'desc': 'Счастливые моменты',   'color': const Color(0xFFEC6A8C)},
    {'path': '6',  'label': 'Антистресс', 'icon': Icons.sports_esports_outlined,'desc': 'Снять напряжение',     'color': const Color(0xFF4A90D9)},
    {'path': '7',  'label': 'Сон',        'icon': Icons.bedtime_outlined,       'desc': 'Трекер сна',           'color': const Color(0xFF5C6BC0)},
    {'path': '8',  'label': 'Тесты',      'icon': Icons.fact_check_outlined,    'desc': 'Психотесты',           'color': const Color(0xFF26A69A)},
    {'path': '9',  'label': 'Упражнения', 'icon': Icons.self_improvement,       'desc': 'Практики',             'color': const Color(0xFF66BB6A)},
    {'path': '10', 'label': 'Аналитика',  'icon': Icons.insights,               'desc': 'Статистика',           'color': const Color(0xFFFFB74D)},
    {'path': '11', 'label': 'Настройки',  'icon': Icons.settings_outlined,      'desc': 'Параметры',            'color': const Color(0xFF8A8A99)},
    {'path': '12', 'label': 'Статьи',     'icon': Icons.menu_book_outlined,     'desc': 'Самопомощь',           'color': const Color(0xFFFF8C42)},
    {'path': '13', 'label': 'Программы',  'icon': Icons.school_outlined,        'desc': 'Мини-курсы',           'color': const Color(0xFF7E57C2)},
    {'path': '14', 'label': 'ИИ-инсайты', 'icon': Icons.tips_and_updates_outlined, 'desc': 'Сводка недели',     'color': const Color(0xFF9C6ADE)},
    {'path': '15', 'label': 'Дерево',     'icon': Icons.park_outlined,          'desc': 'Забота о себе',        'color': const Color(0xFF66BB6A)},
    {'path': '16', 'label': 'Студенту',   'icon': Icons.timer_outlined,         'desc': 'Pomodoro, экзамены',   'color': const Color(0xFF4A90D9)},
  ];

  void _setIndex(int index) {
    setState(() {
      _currentIndex = index;
      _showMenu = false;
    });
    // При переключении на аналитику — запрашиваем актуальные данные
    if (index == 11) {
      (_analyticsKey.currentState as dynamic)?.refreshData();
    }
  }

  bool get _isMenuActive => _currentIndex >= _mainScreenCount;

  bool _isActive(int index) {
    if (index < 4) return _currentIndex == index;
    return _currentIndex == index;
  }

  @override
  Widget build(BuildContext context) {
    // Экран блокировки PIN-кодом (до загрузки данных и до контента приложения)
    if (!_pinChecked) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('🍊', style: TextStyle(fontSize: AppSize.s(48)))),
      );
    }
    if (_pinEnabled && !_unlocked) {
      return PinScreen(canCancel: false, onSuccess: () => setState(() => _unlocked = true));
    }
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              debugPrint('MainNav: AuthAuthenticated, userId=${state.user.id}');
              Future.microtask(() {
                if (context.mounted) {
                  try {
                    context.read<DashboardBloc>().updateUserId(state.user.id, token: state.user.token);
                  } catch (e) {}
                  try {
                    context.read<DiaryBloc>().updateUserId(state.user.id, token: state.user.token);
                  } catch (e) {}
                  try {
                    context.read<SleepBloc>().updateUserId(state.user.id, token: state.user.token);
                  } catch (e) {}
                  try {
                    context.read<ArticleBloc>().setToken(state.user.token);
                  } catch (e) {}
                }
              });
            } else if (state is AuthUnauthenticated) {
              Future.microtask(() {
                if (context.mounted) {
                  context.go('/auth');
                }
              });
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              // Показываем splash пока авторизация не определилась
              if (authState is AuthLoading || authState is AuthInitial) {
                return MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: AppSize.radius(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                              ),
                            ),
                            child: Center(child: Text('🍊', style: TextStyle(fontSize: AppSize.s(32)))),
                          ),
                          AppSize.gapH(24),
                          Text(
                            'Загрузка...',
                            style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (authState is AuthUnauthenticated) {
                return SizedBox.shrink(); // redirect перенаправит на /auth
              }

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarIconBrightness: Brightness.light,
                ),
                child: Scaffold(
                  body: SafeArea(
                    child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: IndexedStack(
                              index: _currentIndex,
                              children: _buildScreens(),
                            ),
                          ),
                          _buildBottomNav(),
                        ],
                      ),
                      if (_showMenu) _buildMenuOverlay(),
                      if (_showEmergency)
                        EmergencyModal(onClose: () => setState(() => _showEmergency = false)),
                    ],
                  ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.citrusOrange.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.citrusOrange.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: AppSize.radius(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.citrusOrange.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text('🍊', style: TextStyle(fontSize: AppSize.s(16))),
                ),
              ),
              AppSize.gapW(8),
              Text(
                'Цитрус',
                style: TextStyle(
                  fontSize: AppSize.s(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                  letterSpacing: -0.5,
                ),
              ),
              AppSize.gapW(6),
              Container(
                padding: AppSize.paddingH(8, 2),
                decoration: BoxDecoration(
                  color: AppColors.citrusOrange.withValues(alpha: 0.15),
                  borderRadius: AppSize.radius(999),
                ),
                child: Text(
                  'Beta',
                  style: TextStyle(
                    fontSize: AppSize.s(10),
                    fontWeight: FontWeight.w500,
                    color: AppColors.citrusOrange,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.subtleBg,
                  borderRadius: AppSize.radius(12),
                ),
                child: Icon(Icons.notifications_none,
                    color: AppColors.mutedForeground, size: 18),
              ),
              AppSize.gapW(8),
              GestureDetector(
                onTap: () => setState(() => _showEmergency = true),
                child: Container(
                  padding: AppSize.paddingH(12, 6),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.15),
                    borderRadius: AppSize.radius(12),
                    border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.destructive, size: 14),
                      AppSize.gapW(4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: AppSize.s(11),
                          fontWeight: FontWeight.w600,
                          color: AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Главная'},
      {'icon': Icons.calendar_today_outlined, 'activeIcon': Icons.calendar_today, 'label': 'Календарь'},
      {'icon': Icons.chat_bubble_outline, 'activeIcon': Icons.chat_bubble, 'label': 'ИИ Чат'},
      {'icon': Icons.book_outlined, 'activeIcon': Icons.book, 'label': 'Дневник'},
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: AppSize.radius(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: AppSize.paddingH(6, 6),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.88),
              borderRadius: AppSize.radius(24),
              border: Border.all(color: AppColors.subtleBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                ...navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final active = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _setIndex(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: AppSize.paddingH(0, 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.citrusOrange.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: AppSize.radius(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
                              color: active
                                  ? AppColors.citrusOrange
                                  : AppColors.dimForeground,
                              size: 20,
                            ),
                            AppSize.gapH(4),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: AppSize.s(10),
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                color: active
                                    ? AppColors.citrusOrange
                                    : AppColors.dimForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // More button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMenu = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: AppSize.paddingH(0, 8),
                      decoration: BoxDecoration(
                        color: _isMenuActive
                            ? AppColors.citrusOrange.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: AppSize.radius(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.grid_view_outlined,
                            color: _isMenuActive
                                ? AppColors.citrusOrange
                                : AppColors.dimForeground,
                            size: 20,
                          ),
                          AppSize.gapH(4),
                          Text(
                            'Ещё',
                            style: TextStyle(
                              fontSize: AppSize.s(10),
                              fontWeight: _isMenuActive ? FontWeight.w600 : FontWeight.w400,
                              color: _isMenuActive
                                  ? AppColors.citrusOrange
                                  : AppColors.dimForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showMenu = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.citrusOrange.withValues(alpha: 0.15)),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Все функции',
                              style: TextStyle(
                                fontSize: AppSize.s(18),
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                            AppSize.gapH(4),
                            Text(
                              'Все инструменты ментального здоровья',
                              style: TextStyle(
                                  fontSize: AppSize.s(11), color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showMenu = false),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.subtleBg,
                              borderRadius: AppSize.radius(12),
                            ),
                            child: Icon(Icons.close,
                                color: AppColors.mutedForeground, size: 18),
                          ),
                        ),
                      ],
                    ),
                    AppSize.gapH(20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      physics: NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: _allFeatures.map((feature) {
                        final featureIndex = int.parse(feature['path'] as String);
                        final isActive = _currentIndex == featureIndex;
                        final featColor = feature['color'] as Color;
                        return GestureDetector(
                        onTap: () {
                          _setIndex(featureIndex);
                        },
                          child: Container(
                            padding: AppSize.paddingH(8, 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.citrusOrange.withValues(alpha: 0.15)
                                  : AppColors.card,
                              borderRadius: AppSize.radius(16),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.citrusOrange.withValues(alpha: 0.35)
                                    : AppColors.subtleBorder,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: AppSize.s(44),
                                  height: AppSize.s(44),
                                  decoration: BoxDecoration(
                                    color: featColor.withValues(alpha: 0.16),
                                    borderRadius: AppSize.radius(14),
                                  ),
                                  child: Center(child: Icon(feature['icon'] as IconData, size: AppSize.s(23), color: featColor)),
                                ),
                                AppSize.gapH(8),
                                Text(
                                  feature['label'] as String,
                                  style: TextStyle(
                                    fontSize: AppSize.s(11),
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? AppColors.citrusOrange
                                        : AppColors.foreground,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AppSize.gapH(1),
                                Text(
                                  feature['desc'] as String,
                                  style: TextStyle(
                                      fontSize: AppSize.s(9),
                                      color: AppColors.dimForeground),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
