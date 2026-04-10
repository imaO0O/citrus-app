import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/theme_service.dart';
import '../screens/home_page.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/media_screen.dart';
import '../screens/affirmations_screen.dart';
import '../screens/photo_gallery_screen.dart';
import '../screens/toy_screen.dart';
import '../screens/sleep_tracker_screen.dart';
import '../screens/tests_screen.dart';
import '../screens/exercises_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/emergency_modal.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../core/repository/sleep_repository.dart';
import '../features/diary/bloc/diary_bloc.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _showMenu = false;
  bool _showEmergency = false;

  // 0-3: main nav screens, 4+: feature screens
  static const _mainScreenCount = 4;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      HomePage(                 // 0 — homepage из test_fornt
        onNavigateToExercises: () => _setIndex(10),
        onNavigateToChat: () => _setIndex(2),
        onNavigateToDiary: () => _setIndex(3),
        onNavigateToSleep: () => _setIndex(8),
      ),
      CalendarScreen(),            // 1
      ChatScreen(),                // 2
      DiaryScreen(),               // 3
      MediaScreen(),               // 4
      AffirmationsScreen(),        // 5
      PhotoGalleryScreen(),        // 6
      ToyScreen(),                 // 7
      SleepTrackerScreen(),        // 8
      TestsScreen(),               // 9
      ExercisesScreen(),           // 10
      AnalyticsScreen(),           // 11
      SettingsScreen(),            // 12
    ]);

    // Инициализация BLoC при старте
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is AuthAuthenticated) {
          debugPrint('MainNav: init — пользователь уже авторизован, userId=${authState.user.id}');
          context.read<DashboardBloc>().updateUserId(authState.user.id, token: authState.user.token);
          context.read<DiaryBloc>().updateUserId(authState.user.id, token: authState.user.token);
        }
      } catch (e) {
        debugPrint('MainNav: ошибка init BLoC: $e');
      }
    });
  }

  final List<Map<String, String>> _allFeatures = const [
    {'path': '4',  'label': 'Медиа',         'icon': '🎬', 'desc': 'Видео и аудио'},
    {'path': '5',  'label': 'Аффирмации',    'icon': '💫', 'desc': 'Позитивные установки'},
    {'path': '6',  'label': 'Галерея',       'icon': '📸', 'desc': 'Счастливые моменты'},
    {'path': '7',  'label': 'Антистресс',    'icon': '🎮', 'desc': 'Снять напряжение'},
    {'path': '8',  'label': 'Сон',           'icon': '🌙', 'desc': 'Трекер сна'},
    {'path': '9',  'label': 'Тесты',         'icon': '📋', 'desc': 'Психотесты'},
    {'path': '10', 'label': 'Упражнения',    'icon': '🧘', 'desc': 'Практики'},
    {'path': '11', 'label': 'Аналитика',     'icon': '📊', 'desc': 'Статистика'},
    {'path': '12', 'label': 'Настройки',     'icon': '⚙️', 'desc': 'Параметры'},
  ];

  void _setIndex(int index) {
    setState(() {
      _currentIndex = index;
      _showMenu = false;
    });
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
                if (mounted) {
                  try {
                    context.read<DashboardBloc>().updateUserId(state.user.id, token: state.user.token);
                  } catch (e) {}
                  try {
                    context.read<DiaryBloc>().updateUserId(state.user.id, token: state.user.token);
                  } catch (e) {}
                }
              });
            } else if (state is AuthUnauthenticated) {
              Future.microtask(() {
                if (mounted) {
                  context.go('/auth');
                }
              });
            }
          },
          child: SafeArea(
            child: Scaffold(
              body: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _screens,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.citrusOrange.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.citrusOrange.withOpacity(0.1)),
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
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.citrusOrange.withOpacity(0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🍊', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Цитрус',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.citrusOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Beta',
                  style: TextStyle(
                    fontSize: 10,
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none,
                    color: AppColors.mutedForeground, size: 18),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showEmergency = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.destructive, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D16).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: AppColors.citrusOrange.withOpacity(0.1)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.citrusOrange.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(height: 4),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 10,
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isMenuActive
                            ? AppColors.citrusOrange.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 4),
                          Text(
                            'Ещё',
                            style: TextStyle(
                              fontSize: 10,
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
        color: Colors.black.withOpacity(0.75),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.citrusOrange.withOpacity(0.15)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                            const Text(
                              'Все функции',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Все инструменты ментального здоровья',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showMenu = false),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close,
                                color: AppColors.mutedForeground, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: _allFeatures.map((feature) {
                        final featureIndex = int.parse(feature['path']!);
                        final isActive = _currentIndex == featureIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentIndex = featureIndex;
                              _showMenu = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.citrusOrange.withOpacity(0.15)
                                  : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.citrusOrange.withOpacity(0.35)
                                    : Colors.white.withOpacity(0.06),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(feature['icon'] as String,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  feature['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isActive
                                        ? AppColors.citrusOrange
                                        : AppColors.foreground,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  feature['desc'] as String,
                                  style: const TextStyle(
                                      fontSize: 9,
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
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.white.withOpacity(0.06))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Быстрый доступ',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.mutedForeground),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.mutedForeground, size: 14),
                        ],
                      ),
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
