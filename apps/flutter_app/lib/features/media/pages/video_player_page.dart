import 'package:flutter/material.dart';

class VideoPlayerPage extends StatelessWidget {
  final String id;
  const VideoPlayerPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Видео $id')),
      body: const Center(child: Text('Плеер видео')),
    );
  }
}