import 'package:flutter/material.dart';

class SOScreen extends StatelessWidget {
  const SOScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: const Center(child: Text('Экстренная помощь')),
    );
  }
}
