import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import 'tests/tests_list_screen.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем токен из AuthBloc
    String? token;
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      token = authState.user.token;
    }

    return TestsListScreen(token: token);
  }
}
