import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дневник')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Быстрые отметки настроения (дольки дня)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Здесь будет вызов BLoC
              },
              child: const Text('Добавить отметку'),
            ),
            const SizedBox(height: 20),
            const Text('Последние записи дневника'),
            // Здесь можно вывести список записей
          ],
        ),
      ),
    );
  }
}