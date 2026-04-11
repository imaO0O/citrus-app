import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/repository/auth_repository.dart';
import 'core/repository/sleep_repository.dart';
import 'core/repository/calendar_event_repository.dart';
import 'core/repository/diary_repository.dart';
import 'core/repository/mood_repository.dart';
import 'core/repository/memory_photo_repository.dart';
import 'bloc/dashboard_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/sleep/bloc/sleep_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/diary/bloc/diary_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация сервиса тем
  await ThemeService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Создаем репозитории
    final authRepository = AuthRepository();
    final sleepRepository = SleepRepository(userId: 'unknown', token: null);
    final calendarRepository = CalendarEventRepository(userId: 'unknown', token: null);
    final diaryRepository = DiaryRepository(userId: 'unknown', token: null);
    final moodRepository = MoodRepository(userId: 'unknown', token: null);
    final memoryPhotoRepository = MemoryPhotoRepository(userId: 'unknown', token: null);

    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: authRepository),
            RepositoryProvider.value(value: sleepRepository),
            RepositoryProvider.value(value: calendarRepository),
            RepositoryProvider.value(value: diaryRepository),
            RepositoryProvider.value(value: moodRepository),
            RepositoryProvider.value(value: memoryPhotoRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) {
                  final authBloc = AuthBloc(repository: authRepository)..add(const AuthInit());

                  // Слушаем изменения состояния авторизации
                  authBloc.stream.listen((state) {
                    if (state is AuthAuthenticated) {
                      final userId = state.user.id;
                      final token = state.user.token;
                      debugPrint('Auth: пользователь вошёл, userId=$userId');
                      sleepRepository.setUserId(userId, token: token);
                      calendarRepository.setUserId(userId, token: token);
                      diaryRepository.setUserId(userId, token: token);
                      moodRepository.setUserId(userId, token: token);
                      memoryPhotoRepository.setUserId(userId, token: token);
                    } else if (state is AuthUnauthenticated) {
                      debugPrint('Auth: пользователь вышел');
                      sleepRepository.setUserId('unknown', token: null);
                      calendarRepository.setUserId('unknown', token: null);
                      diaryRepository.setUserId('unknown', token: null);
                      moodRepository.setUserId('unknown', token: null);
                      memoryPhotoRepository.setUserId('unknown', token: null);
                    }
                  });

                  return authBloc;
                },
              ),
              BlocProvider(create: (_) {
                final dashboardBloc = DashboardBloc();
                dashboardBloc.setSleepRepository(sleepRepository);
                return dashboardBloc;
              }),
              BlocProvider(
                create: (ctx) => SleepBloc(repository: ctx.read<SleepRepository>()),
              ),
              BlocProvider(
                create: (ctx) => CalendarBloc(
                  repository: ctx.read<CalendarEventRepository>(),
                  moodRepository: ctx.read<MoodRepository>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => DiaryBloc(repository: ctx.read<DiaryRepository>()),
              ),
            ],
            child: MaterialApp.router(
              title: 'Citrus',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: ThemeService().themeMode,
              routerConfig: AppRouter().router,
              debugShowCheckedModeBanner: false,
              locale: const Locale('ru', 'RU'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ru', 'RU'),
                Locale('en', 'US'),
              ],
            ),
          ),
        );
      },
    );
  }
}
