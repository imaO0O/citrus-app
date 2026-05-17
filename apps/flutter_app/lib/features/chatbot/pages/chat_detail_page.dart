import 'package:flutter/material.dart';

class ChatDetailPage extends StatelessWidget {
  final String id;
  const ChatDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Чат $id')),
      body: const Center(child: Text('Диалог с ботом')),
    );
  }
}