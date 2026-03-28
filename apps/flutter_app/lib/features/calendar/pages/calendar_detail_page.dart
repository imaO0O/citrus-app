import 'package:flutter/material.dart';

class CalendarDetailPage extends StatelessWidget {
  final DateTime date;
  const CalendarDetailPage({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Детали за ${date.toLocal()}')),
      body: const Center(child: Text('Список отметок и событий за день')),
    );
  }
}