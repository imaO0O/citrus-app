import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../screens/main_navigation_screen.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/bloc/auth_bloc.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      
      final isAuthPage = state.fullPath == '/auth' ||
          state.fullPath == '/login' ||
          state.fullPath == '/register';
      
      final isLoggingIn = state.fullPath == '/login';
      final isRegistering = state.fullPath == '/register';

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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_stories,
                  size: 100,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Citrus',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ваш персональный помощник',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => context.pushNamed('login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Войти',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.pushNamed('register'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
