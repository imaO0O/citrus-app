import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../screens/main_navigation_screen.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/bloc/auth_bloc.dart';

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
        builder: (context, state) => const AuthSelectionPage(),
      ),
      // Вход
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // Регистрация
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      // Основной маршрут — главная навигация со всеми экранами
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
  );
}

class AuthSelectionPage extends StatelessWidget {
  const AuthSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowOrange,
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🍊',
                        style: TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Цитрус',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'Ваш персональный помощник\nдля ментального здоровья',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 64),
                  
                  // Login button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowOrange,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
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
                          borderRadius: BorderRadius.circular(AppColors.radius),
                        ),
                      ),
                      child: const Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Register button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppColors.radius),
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
                          borderRadius: BorderRadius.circular(AppColors.radius),
                        ),
                      ),
                      child: const Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Footer text
                  Text(
                    'Продолжая, вы соглашаетесь с условиями использования',
                    style: TextStyle(
                      fontSize: 12,
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
