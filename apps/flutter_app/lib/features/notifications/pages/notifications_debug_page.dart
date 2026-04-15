import 'package:flutter/material.dart';
import '../../../services/notification_service.dart';

/// Страница для отладки уведомлений
class NotificationsDebugPage extends StatefulWidget {
  const NotificationsDebugPage({super.key});

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
        title: const Text('Отладка уведомлений'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.notifications, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Статус',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _testInstantNotification,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Отправить тестовое уведомление'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _checkPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Проверить разрешения'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _requestPermissions,
              icon: const Icon(Icons.key),
              label: const Text('Запросить разрешения'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _getPendingNotifications,
              icon: const Icon(Icons.list),
              label: const Text('Список запланированных'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
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
