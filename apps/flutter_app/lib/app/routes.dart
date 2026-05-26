import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../screens/main_navigation_screen.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/notifications/pages/notifications_page.dart';
import '../features/notifications/pages/notifications_debug_page.dart';
import '../core/utils/app_size.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;

      // Пока идёт инициализация — не перенаправляем, показываем loader
      if (authState is AuthLoading || authState is AuthInitial) {
        return null;
      }

      final isAuthenticated = authState is AuthAuthenticated;

      final isAuthPage = state.fullPath == '/auth' ||
          state.fullPath == '/login' ||
          state.fullPath == '/register';

      // Если авторизован и на auth странице — перенаправляем на главную
      if (isAuthenticated && isAuthPage) {
        return '/';
      }

      // Если не авторизован и пытается зайти не на auth страницу
      if (!isAuthenticated && !isAuthPage) {
        return '/auth';
      }

      return null;
    },
    routes: [
      // Страница выбора входа/регистрации
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => AuthSelectionPage(),
      ),
      // Вход
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(),
      ),
      // Регистрация
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterPage(),
      ),
      // Основной маршрут — главная навигация со всеми экранами
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => MainNavigationScreen(),
      ),
      // Настройки уведомлений
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => NotificationsPage(),
      ),
      // Отладка уведомлений (только для разработки)
      GoRoute(
        path: '/debug/notifications',
        name: 'notifications_debug',
        builder: (context, state) => NotificationsDebugPage(),
      ),
    ],
  );
}

class AuthSelectionPage extends StatelessWidget {
  AuthSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSize.padding(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: AppSize.radius(36),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowOrange,
                          blurRadius: 40,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '🍊',
                        style: TextStyle(fontSize: AppSize.s(56)),
                      ),
                    ),
                  ),
                  AppSize.gapH(32),
                  
                  // Title
                  Text(
                    'Цитрус',
                    style: TextStyle(
                      fontSize: AppSize.s(40),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  AppSize.gapH(12),
                  
                  // Subtitle
                  Text(
                    'Ваш персональный помощник\nдля ментального здоровья',
                    style: TextStyle(
                      fontSize: AppSize.s(16),
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSize.gapH(64),
                  
                  // Login button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                      borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowOrange,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => context.pushNamed('login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                        ),
                      ),
                      child: Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  AppSize.gapH(16),
                  
                  // Register button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                      border: Border.all(
                        color: AppColors.citrusOrange.withOpacity(0.5),
                      ),
                    ),
                    child: OutlinedButton(
                      onPressed: () => context.pushNamed('register'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.citrusOrange,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                        ),
                      ),
                      child: Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  AppSize.gapH(48),
                  
                  // Footer text
                  Text(
                    'Продолжая, вы соглашаетесь с условиями использования',
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      color: AppColors.dimForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
