import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';
import '../../../core/utils/app_size.dart';

/// Страница для отладки уведомлений
class NotificationsDebugPage extends StatefulWidget {
  NotificationsDebugPage({super.key});

  @override
  State<NotificationsDebugPage> createState() => _NotificationsDebugPageState();
}

class _NotificationsDebugPageState extends State<NotificationsDebugPage> {
  final NotificationService _service = NotificationService();
  String _status = 'Нажмите кнопку для проверки';
  bool _loading = false;

  Future<void> _testInstantNotification() async {
    setState(() {
      _loading = true;
      _status = 'Отправка уведомления...';
    });

    try {
      await _service.showInstantNotification(
        title: '🔔 Тестовое уведомление',
        body: 'Если вы видите это, уведомления работают!',
        channelId: 'general',
      );
      setState(() => _status = '✅ Уведомление отправлено!');
    } catch (e) {
      setState(() => _status = '❌ Ошибка: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _loading = true;
      _status = 'Проверка разрешений...';
    });

    try {
      final enabled = await _service.areNotificationsEnabled();
      setState(() => _status = 'Разрешения: ${enabled ? "✅ Предоставлены" : "❌ Нет разрешений"}');
    } catch (e) {
      setState(() => _status = '❌ Ошибка проверки: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _loading = true;
      _status = 'Запрос разрешений...';
    });

    try {
      final granted = await _service.requestPermissions();
      setState(() => _status = 'Результат: ${granted ? "✅ Разрешено" : "❌ Отклонено"}');
    } catch (e) {
      setState(() => _status = '❌ Ошибка: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _getPendingNotifications() async {
    setState(() {
      _loading = true;
      _status = 'Получение списка...';
    });

    try {
      final pending = await _service.getPendingNotifications();
      setState(() => _status = 'Запланировано уведомлений: ${pending.length}');
    } catch (e) {
      setState(() => _status = '❌ Ошибка: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отладка уведомлений'),
      ),
      body: Padding(
        padding: AppSize.padding(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSize.padding(16.0),
                child: Column(
                  children: [
                    Icon(Icons.notifications, size: 48),
                    AppSize.gapH(8),
                    Text(
                      'Статус',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AppSize.gapH(8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            AppSize.gapH(16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _testInstantNotification,
              icon: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send),
              label: Text('Отправить тестовое уведомление'),
            ),
            AppSize.gapH(8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _checkPermissions,
              icon: Icon(Icons.security),
              label: Text('Проверить разрешения'),
            ),
            AppSize.gapH(8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _requestPermissions,
              icon: Icon(Icons.key),
              label: Text('Запросить разрешения'),
            ),
            AppSize.gapH(8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _getPendingNotifications,
              icon: Icon(Icons.list),
              label: Text('Список запланированных'),
            ),
            AppSize.gapH(16),
            Divider(),
            Text(
              'Если уведомления не приходят:\n'
              '1. Проверьте разрешения в настройках Android\n'
              '2. Убедитесь, что канал уведомлений включен\n'
              '3. Проверьте, что батарейная оптимизация отключена',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
