import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Экстренная помощь')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final phone = 'tel:112';
                if (await canLaunch(phone)) {
                  await launch(phone);
                }
              },
              child: const Text('Позвонить на горячую линию'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Отправить SOS сообщение
              },
              child: const Text('Отправить SOS доверенному контакту'),
            ),
          ],
        ),
      ),
    );
  }
}