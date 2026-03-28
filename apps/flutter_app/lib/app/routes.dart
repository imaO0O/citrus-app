import 'package:flutter/material.dart';
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

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
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

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Дневник'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Календарь'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Чат-бот'),
          NavigationDestination(icon: Icon(Icons.video_library), label: 'Медиа'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
      floatingActionButton: navigationShell.currentIndex == 4
          ? FloatingActionButton.extended(
              onPressed: () {
                context.pushNamed('emergency');
              },
              icon: const Icon(Icons.warning),
              label: const Text('Красная кнопка'),
              backgroundColor: Colors.red,
            )
          : null,
    );
  }
}