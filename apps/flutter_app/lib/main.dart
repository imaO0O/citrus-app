import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'app/routes.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/calendar/bloc/calendar_bloc.dart';
import 'features/chatbot/bloc/chatbot_bloc.dart';
import 'features/media/bloc/media_bloc.dart';
import 'features/profile/bloc/profile_bloc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final GoRouter _router = AppRouter().router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardBloc()),
        BlocProvider(create: (_) => CalendarBloc()),
        BlocProvider(create: (_) => ChatbotBloc()),
        BlocProvider(create: (_) => MediaBloc()),
        BlocProvider(create: (_) => ProfileBloc()),
      ],
      child: MaterialApp.router(
        title: 'Your App',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}