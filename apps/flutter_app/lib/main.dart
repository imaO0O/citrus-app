import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes.dart';
import 'core/utils/theme.dart';
import 'core/utils/theme_service.dart';
import 'core/repository/auth_repository.dart';
import 'bloc/dashboard_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';

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

    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: authRepository),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) {
                  final authBloc = AuthBloc(repository: authRepository)..add(const AuthInit());
                  return authBloc;
                },
              ),
              BlocProvider(create: (_) => DashboardBloc()),
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
