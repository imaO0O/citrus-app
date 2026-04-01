import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/repository/calendar_event_repository.dart';
import 'core/repository/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart' as auth_bloc;
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/chatbot/bloc/chatbot_bloc.dart';
import 'features/media/bloc/media_bloc.dart';
import 'features/profile/bloc/profile_bloc.dart';

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
    final calendarRepository = CalendarEventRepository(userId: 'unknown');

    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: authRepository),
            RepositoryProvider<CalendarEventRepository>(
              create: (_) => calendarRepository,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) {
                  final authBloc = AuthBloc(repository: authRepository)..add(const AuthInit());
                  // Слушаем изменения состояния авторизации
                  authBloc.stream.listen((state) {
                    if (state is auth_bloc.AuthAuthenticated) {
                      // Пользователь вошёл — обновляем userId и токен в календаре
                      calendarRepository.setUserId(state.user.id, token: state.user.token);
                    } else if (state is auth_bloc.AuthUnauthenticated) {
                      // Пользователь вышел — сбрасываем
                      calendarRepository.setUserId('unknown', token: null);
                    }
                  });
                  return authBloc;
                },
              ),
              BlocProvider(create: (_) => DashboardBloc()),
              BlocProvider(
                create: (_) => CalendarBloc(repository: calendarRepository),
              ),
              BlocProvider(create: (_) => ChatbotBloc()),
              BlocProvider(create: (_) => MediaBloc()),
              BlocProvider(
                create: (_) => ProfileBloc(authRepository: authRepository),
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
