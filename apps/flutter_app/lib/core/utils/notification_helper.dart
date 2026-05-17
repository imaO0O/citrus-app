import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

/// Помощник для работы с разрешениями уведомлений
class NotificationHelper {
  /// Запросить разрешения на уведомления
  static Future<bool> requestPermissions(BuildContext context) async {
    final service = NotificationService();
    
    // Проверяем, включены ли уведомления
    final enabled = await service.areNotificationsEnabled();
    if (enabled) return true;
    
    // Показываем диалог перед запросом (опционально)
    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔔 Уведомления'),
          content: const Text(
            'Приложение использует уведомления для:\n'
            '• Напоминаний о событиях в календаре\n'
            '• Напоминаний отметить сон\n'
            '• Напоминаний отметить настроение\n'
            '• Напоминаний сделать запись в дневнике\n\n'
            'Разрешить уведомления?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Разрешить'),
            ),
          ],
        ),
      );
      
      if (shouldRequest != true) return false;
    }
    
    // Запрашиваем разрешения
    return await service.requestPermissions();
  }
  
  /// Проверить и запросить разрешения без диалога
  static Future<bool> ensurePermissions() async {
    final service = NotificationService();
    
    final enabled = await service.areNotificationsEnabled();
    if (enabled) return true;
    
    return await service.requestPermissions();
  }
}
