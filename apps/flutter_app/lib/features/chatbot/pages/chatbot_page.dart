import 'package:flutter/material.dart';

class ChatbotPage extends StatelessWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат-бот')),
      body: const Center(
        child: Text('Здесь будет интерфейс чата с ИИ-ассистентом'),
      ),
    );
  }
}