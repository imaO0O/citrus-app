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
import '../screens/emergency_modal.dart';
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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showMenu = false;
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
      const CoursesListScreen(),   // 13
      const WeeklyInsightsScreen(), // 14
      const CitrusTreeScreen(),    // 15
      const StudentScreen(),       // 16
    ];
  }

  @override
  void initState() {
    super.initState();

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
    });
  }

  final List<Map<String, String>> _allFeatures = [
    {'path': '4',  'label': 'Аффирмации',    'icon': '💫', 'desc': 'Позитивные установки'},
    {'path': '5',  'label': 'Галерея',       'icon': '📸', 'desc': 'Счастливые моменты'},
    {'path': '6',  'label': 'Антистресс',    'icon': '🎮', 'desc': 'Снять напряжение'},
    {'path': '7',  'label': 'Сон',           'icon': '🌙', 'desc': 'Трекер сна'},
    {'path': '8',  'label': 'Тесты',         'icon': '📋', 'desc': 'Психотесты'},
    {'path': '9',  'label': 'Упражнения',    'icon': '🧘', 'desc': 'Практики'},
    {'path': '10', 'label': 'Аналитика',     'icon': '📊', 'desc': 'Статистика'},
    {'path': '11', 'label': 'Настройки',     'icon': '⚙️', 'desc': 'Параметры'},
    {'path': '12', 'label': 'Статьи',        'icon': '📖', 'desc': 'Самопомощь'},
    {'path': '13', 'label': 'Программы',     'icon': '🎓', 'desc': 'Мини-курсы'},
    {'path': '14', 'label': 'ИИ-инсайты',    'icon': '✨', 'desc': 'Сводка недели'},
    {'path': '15', 'label': 'Дерево',        'icon': '🌳', 'desc': 'Забота о себе'},
    {'path': '16', 'label': 'Студенту',      'icon': '📚', 'desc': 'Pomodoro, экзамены'},
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
                  color: Colors.white.withValues(alpha: 0.05),
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

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.citrusOrange.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppSize.radius(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: AppSize.paddingH(4, 4),
            decoration: BoxDecoration(
              color: AppColors.foreground.withValues(alpha: 0.03),
              borderRadius: AppSize.radius(16),
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
                      child: Container(
                        padding: AppSize.paddingH(0, 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.citrusOrange.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: AppSize.radius(12),
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
                    child: Container(
                      padding: AppSize.paddingH(0, 8),
                      decoration: BoxDecoration(
                        color: _isMenuActive
                            ? AppColors.citrusOrange.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: AppSize.radius(12),
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
                              color: Colors.white.withValues(alpha: 0.08),
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
                        final featureIndex = int.parse(feature['path']!);
                        final isActive = _currentIndex == featureIndex;
                        return GestureDetector(
                        onTap: () {
                          _setIndex(featureIndex);
                        },
                          child: Container(
                            padding: AppSize.paddingH(8, 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.citrusOrange.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: AppSize.radius(16),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.citrusOrange.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(feature['icon'] as String,
                                    style: TextStyle(fontSize: AppSize.s(22))),
                                AppSize.gapH(4),
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
