import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Настройка предпочтений по статьям'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Настройка уведомлений'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Выгрузка аналитики'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Трекер сна'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Тесты (подходящий отдых)'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Создать кастомную статью'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}