import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/notification_service.dart';
import '../bloc/notification_settings_bloc.dart';

/// Экран настроек уведомлений
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationSettingsBloc(
        repository: context.read<NotificationPreferencesRepository>(),
      )..add(const LoadNotificationSettings()),
      child: const _NotificationsPageContent(),
    );
  }
}

class _NotificationsPageContent extends StatelessWidget {
  const _NotificationsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        centerTitle: true,
      ),
      body: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationSettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationSettingsBloc>().add(
                        const LoadNotificationSettings(),
                      );
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationSettingsLoaded) {
            return _NotificationSettingsList(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationSettingsList extends StatelessWidget {
  final NotificationSettingsLoaded state;

  const _NotificationSettingsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final prefs = state.preferences;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Предупреждение об отсутствии разрешений
        if (!state.permissionsGranted)
          _buildPermissionWarning(context),

        const SizedBox(height: 8),

        // Календарь
        _buildSection(
          context,
          icon: Icons.calendar_today,
          title: 'События календаря',
          child: _CalendarSettings(
            enabled: prefs.calendarNotificationsEnabled,
            reminderMinutes: prefs.calendarReminderMinutes,
          ),
        ),

        const SizedBox(height: 16),

        // Сон
        _buildSection(
          context,
          icon: Icons.bedtime,
          title: 'Напоминания о сне',
          child: _SleepSettings(
            enabled: prefs.sleepRemindersEnabled,
            morningTime: prefs.sleepMorningTime,
            eveningTime: prefs.sleepEveningTime,
          ),
        ),

        const SizedBox(height: 16),

        // Настроение
        _buildSection(
          context,
          icon: Icons.mood,
          title: 'Напоминания о настроении',
          child: _MoodSettings(
            enabled: prefs.moodRemindersEnabled,
            reminderTimes: prefs.moodReminderTimes,
          ),
        ),

        const SizedBox(height: 16),

        // Дневник
        _buildSection(
          context,
          icon: Icons.book,
          title: 'Напоминания о дневнике',
          child: _DiarySettings(
            enabled: prefs.diaryRemindersEnabled,
            reminderTime: prefs.diaryReminderTime,
            includeMoodPrompt: prefs.diaryIncludeMoodPrompt,
          ),
        ),

        const SizedBox(height: 24),

        // Кнопка тестирования
        _buildTestSection(context),
      ],
    );
  }

  Widget _buildPermissionWarning(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_off, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Text(
                  'Уведомления отключены',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Для работы напоминаний необходимо разрешение на отправку уведомлений.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.read<NotificationSettingsBloc>().add(
                  const RequestNotificationPermissions(),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Разрешить уведомления'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Тестирование',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text('Отправить тестовое уведомление:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TestButton(
                  label: 'Календарь',
                  icon: Icons.calendar_today,
                  onPressed: () => _sendTestNotification(context, 'calendar'),
                ),
                _TestButton(
                  label: 'Сон',
                  icon: Icons.bedtime,
                  onPressed: () => _sendTest