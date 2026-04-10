import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/repository/auth_repository.dart';
import 'core/repository/sleep_repository.dart';
import 'core/repository/calendar_event_repository.dart';
import 'bloc/dashboard_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/sleep/bloc/sleep_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';

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

    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: authRepository),
            RepositoryProvider.value(value: sleepRepository),
            RepositoryProvider.value(value: calendarRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) {
                  final authBloc = AuthBloc(repository: authRepository)..add(const AuthInit());

                  // Слушаем изменения состояния авторизации
                  authBloc.stream.listen((state) {
                    if (state is AuthAuthenticated) {
                      // Пользователь вошёл — обновляем userId и токен
                      final userId = state.user.id;
                      final token = state.user.token;
                      debugPrint('Auth: пользователь вошёл, userId=$userId, token=${token.isEmpty ? "пустой" : "length=${token.length}"}');
                      sleepRepository.setUserId(userId, token: token);
                      calendarRepository.setUserId(userId, token: token);
                    } else if (state is AuthUnauthenticated) {
                      // Пользователь вышел — сбрасываем
                      debugPrint('Auth: пользователь вышел, сброс репозиториев');
                      sleepRepository.setUserId('unknown', token: null);
                      calendarRepository.setUserId('unknown', token: null);
                    }
                  });

                  return authBloc;
                },
              ),
              BlocProvider(create: (_) => DashboardBloc()),
              BlocProvider(
                create: (ctx) => SleepBloc(repository: ctx.read<SleepRepository>()),
              ),
              BlocProvider(
                create: (ctx) => CalendarBloc(repository: ctx.read<CalendarEventRepository>()),
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
