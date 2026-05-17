import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../../core/utils/app_size.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Дневник')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Быстрые отметки настроения (дольки дня)'),
            AppSize.gapH(20),
            ElevatedButton(
              onPressed: () {
                // Здесь будет вызов BLoC
              },
              child: Text('Добавить отметку'),
            ),
            AppSize.gapH(20),
            Text('Последние записи дневника'),
            // Здесь можно вывести список записей
          ],
        ),
      ),
    );
  }
}