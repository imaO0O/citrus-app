import 'package:flutter/material.dart';

class AudioPlayerPage extends StatelessWidget {
  final String id;
  const AudioPlayerPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Аудио $id')),
      body: const Center(child: Text('Плеер аудио')),
    );
  }
}