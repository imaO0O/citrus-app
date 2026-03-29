import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/calendar/pages/calendar_page.dart';
import '../features/chatbot/pages/chatbot_page.dart';
import '../features/media/pages/media_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/calendar/pages/calendar_detail_page.dart';
import '../features/chatbot/pages/chat_detail_page.dart';
import '../features/media/pages/video_player_page.dart';
import '../features/media/pages/audio_player_page.dart';
import '../features/emergency/pages/emergency_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/pages/home_wrapper.dart';
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
      // Основной маршрут с навигацией
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeWrapper(child: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                builder: (context, state) => const CalendarPage(),
                routes: [
                  GoRoute(
                    path: ':date',
                    name: 'calendarDetail',
                    builder: (context, state) => CalendarDetailPage(
                      date: DateTime.parse(state.pathParameters['date']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chatbot',
                name: 'chatbot',
                builder: (context, state) => const ChatbotPage(),
                routes: [
                  GoRoute(
                    path: 'chat/:id',
                    name: 'chatDetail',
                    builder: (context, state) => ChatDetailPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/media',
                name: 'media',
                builder: (context, state) => const MediaPage(),
                routes: [
                  GoRoute(
                    path: 'video/:id',
                    name: 'videoPlayer',
                    builder: (context, state) => VideoPlayerPage(id: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'audio/:id',
                    name: 'audioPlayer',
                    builder: (context, state) => AudioPlayerPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'emergency',
                    name: 'emergency',
                    builder: (context, state) => const EmergencyPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
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
