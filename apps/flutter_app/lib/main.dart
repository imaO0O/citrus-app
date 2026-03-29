import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/repository/calendar_event_repository.dart';
import 'core/repository/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
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
    // CalendarRepository будет создан после входа с реальным userId
    CalendarEventRepository? calendarRepository;

    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: authRepository),
            RepositoryProvider<CalendarEventRepository?>(
              create: (_) => null, // Будет создан после входа
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => AuthBloc(repository: authRepository)..add(const AuthInit())),
              BlocProvider(create: (_) => DashboardBloc()),
              BlocProvider(
                create: (_) {
                  final user = authRepository.currentUser;
                  if (user != null) {
                    calendarRepository = CalendarEventRepository(userId: user.id);
                  }
                  return CalendarBloc(repository: calendarRepository ?? CalendarEventRepository(userId: 'unknown'));
                },
              ),
              BlocProvider(create: (_) => ChatbotBloc()),
              BlocProvider(create: (_) => MediaBloc()),
              BlocProvider(create: (_) => ProfileBloc()),
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
