import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/utils/app_size.dart';
import 'core/repository/auth_repository.dart';
import 'core/repository/sleep_repository.dart';
import 'core/repository/calendar_event_repository.dart';
import 'core/repository/diary_repository.dart';
import 'core/repository/mood_repository.dart';
import 'core/repository/memory_photo_repository.dart';
import 'core/repository/article_repository.dart';
import 'core/repository/notification_preferences_repository.dart';
import 'services/notification_service.dart';
import 'bloc/dashboard_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/sleep/bloc/sleep_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/diary/bloc/diary_bloc.dart';
import 'features/articles/bloc/article_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройка статус-бара и навигации
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Инициализация сервиса тем (с таймаутом)
  debugPrint('main: init ThemeService...');
  await ThemeService().init().timeout(
    Duration(seconds: 5),
    onTimeout: () => debugPrint('main: ThemeService init timeout'),
  );
  debugPrint('main: ThemeService initialized');

  // Инициализация сервиса уведомлений (с таймаутом, не блокируем запуск)
  debugPrint('main: init NotificationService...');
  NotificationService().initialize().timeout(
    Duration(seconds: 10),
    onTimeout: () => debugPrint('main: NotificationService init timeout'),
  ).catchError((e) => debugPrint('main: NotificationService error: $e'));
  debugPrint('main: NotificationService started (non-blocking)');

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Создаем репозитории и роутер один раз — не пересоздаём при rebuild
  final authRepository = AuthRepository();
  final sleepRepository = SleepRepository(userId: 'unknown', token: null);
  final calendarRepository = CalendarEventRepository(userId: 'unknown', token: null);
  final diaryRepository = DiaryRepository(userId: 'unknown', token: null);
  final moodRepository = MoodRepository(userId: 'unknown', token: null);
  final memoryPhotoRepository = MemoryPhotoRepository(userId: 'unknown', token: null);
  final articleRepository = ArticleRepository();
  final notificationPreferencesRepository = NotificationPreferencesRepository();
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
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
            RepositoryProvider.value(value: articleRepository),
            RepositoryProvider.value(value: notificationPreferencesRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) {
                  final authBloc = AuthBloc(
                    repository: authRepository,
                    notificationRepository: notificationPreferencesRepository,
                  )..add(AuthInit());

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
                      articleRepository.setToken(token);
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
                create: (ctx) => SleepBloc(
                  repository: ctx.read<SleepRepository>(),
                  notificationRepository: ctx.read<NotificationPreferencesRepository>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => CalendarBloc(
                  repository: ctx.read<CalendarEventRepository>(),
                  moodRepository: ctx.read<MoodRepository>(),
                  notificationRepository: ctx.read<NotificationPreferencesRepository>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => DiaryBloc(
                  repository: ctx.read<DiaryRepository>(),
                  notificationRepository: ctx.read<NotificationPreferencesRepository>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => ArticleBloc(repository: ctx.read<ArticleRepository>()),
              ),
            ],
            child: Builder(
              builder: (ctx) {
                AppSize.init(ctx);
                return MaterialApp.router(
                  title: 'Citrus',
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: ThemeService().themeMode,
                  routerConfig: _appRouter.router,
                  debugShowCheckedModeBanner: false,
                  locale: Locale('ru', 'RU'),
                  localizationsDelegates: [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: [
                    Locale('ru', 'RU'),
                    Locale('en', 'US'),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
