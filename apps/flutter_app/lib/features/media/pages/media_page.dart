import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MediaPage extends StatelessWidget {
  const MediaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Медиа')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Антистресс видео'),
            onTap: () {
              context.pushNamed('videoPlayer', pathParameters: {'id': '1'});
            },
          ),
          ListTile(
            title: const Text('Успокаивающие аудио'),
            onTap: () {
              context.pushNamed('audioPlayer', pathParameters: {'id': '1'});
            },
          ),
          ListTile(
            title: const Text('Дофамина галерея'),
            onTap: () {
              // Пока заглушка
            },
          ),
          ListTile(
            title: const Text('Успокаивающая игрушка'),
            onTap: () {
              // Пока заглушка
            },
          ),
        ],
      ),
    );
  }
}