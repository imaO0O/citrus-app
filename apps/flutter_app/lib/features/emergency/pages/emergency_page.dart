import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/app_size.dart';

class EmergencyPage extends StatelessWidget {
  EmergencyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Экстренная помощь')),
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
              child: Text('Позвонить на горячую линию'),
            ),
            AppSize.gapH(20),
            ElevatedButton(
              onPressed: () {
                // Отправить SOS сообщение
              },
              child: Text('Отправить SOS доверенному контакту'),
            ),
          ],
        ),
      ),
    );
  }
}