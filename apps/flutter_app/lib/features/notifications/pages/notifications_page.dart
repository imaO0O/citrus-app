import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/notification_preferences_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/notification_settings_bloc.dart';
import '../../../core/utils/app_size.dart';

class NotificationsPage extends StatelessWidget {
  NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationSettingsBloc(
        repository: context.read<NotificationPreferencesRepository>(),
      )..add(LoadNotificationSettings()),
      child: _NotificationsPageContent(),
    );
  }
}

class _NotificationsPageContent extends StatelessWidget {
  _NotificationsPageContent();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Уведомления'), centerTitle: true),
      body: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
        builder: (context, state) {
          if (state is NotificationSettingsLoading) return Center(child: CircularProgressIndicator());
          if (state is NotificationSettingsError) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.citrusOrange), AppSize.gapH(16),
            Text(state.message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge), AppSize.gapH(16),
            ElevatedButton(onPressed: () => context.read<NotificationSettingsBloc>().add(LoadNotificationSettings()), child: Text('Повторить')),
          ]));
          if (state is NotificationSettingsLoaded) return _NotificationSettingsList(state: state);
          return SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationSettingsList extends StatelessWidget {
  final NotificationSettingsLoaded state;
  _NotificationSettingsList({required this.state});
  @override
  Widget build(BuildContext context) {
    final p = state.preferences;
    return ListView(padding: AppSize.padding(16), children: [
      if (!state.permissionsGranted) _buildPermissionWarning(context), AppSize.gapH(8),
      _buildSection(context, icon: Icons.calendar_today, iconColor: Color(0xFF2196F3), title: 'События календаря', child: _CalendarSettings(enabled: p.calendarNotificationsEnabled, reminderMinutes: p.calendarReminderMinutes)), AppSize.gapH(16),
      _buildSection(context, icon: Icons.bedtime, iconColor: Color(0xFF9C27B0), title: 'Напоминания о сне', child: _SleepSettings(enabled: p.sleepRemindersEnabled, morningTime: p.sleepMorningTime, eveningTime: p.sleepEveningTime)), AppSize.gapH(16),
      _buildSection(context, icon: Icons.mood, iconColor: Color(0xFF4CAF50), title: 'Напоминания о настроении', child: _MoodSettings(enabled: p.moodRemindersEnabled, reminderTimes: p.moodReminderTimes)), AppSize.gapH(16),
      _buildSection(context, icon: Icons.book, iconColor: Color(0xFFFF9800), title: 'Напоминания о дневнике', child: _DiarySettings(enabled: p.diaryRemindersEnabled, reminderTime: p.diaryReminderTime, includeMoodPrompt: p.diaryIncludeMoodPrompt)), AppSize.gapH(24),
      // _buildTestSection(context),
    ]);
  }

  Widget _buildPermissionWarning(BuildContext context) => Container(padding: AppSize.padding(16), decoration: BoxDecoration(color: AppColors.citrusOrange.withOpacity(0.1), borderRadius: AppSize.radius(16), border: Border.all(color: AppColors.citrusOrange.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.notifications_off, color: AppColors.citrusOrange), AppSize.gapW(8), Text('Уведомления отключены', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.citrusOrange))]),
      AppSize.gapH(8), Text('Для работы напоминаний необходимо разрешение на отправку уведомлений.', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))),
      AppSize.gapH(12), ElevatedButton.icon(onPressed: () => context.read<NotificationSettingsBloc>().add(RequestNotificationPermissions()), icon: Icon(Icons.notifications_active, size: 18), label: Text('Разрешить уведомления'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.citrusOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)))),
    ]));

  Widget _buildSection(BuildContext context, {required IconData icon, required Color iconColor, required String title, required Widget child}) =>
    Container(decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(20), border: Border.all(color: AppColors.subtleBorder)),
      child: Padding(padding: AppSize.padding(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: AppSize.radius(10)), child: Icon(icon, color: iconColor, size: 20)), AppSize.gapW(12), Expanded(child: Text(title, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w600)))]),
        AppSize.gapH(12), child,
      ])));

  Widget _buildTestSection(BuildContext context) => Container(decoration: BoxDecoration(color: AppColors.surface1, borderRadius: AppSize.radius(20), border: Border.all(color: AppColors.subtleBorder)),
    child: Padding(padding: AppSize.padding(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.dimForeground.withOpacity(0.1), borderRadius: AppSize.radius(10)), child: Icon(Icons.science, color: AppColors.mutedForeground, size: 20)), AppSize.gapW(12), Text('Тестирование', style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w600))]),
      AppSize.gapH(12), Text('Отправить тестовое уведомление:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))), AppSize.gapH(12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _TestButton(label: 'Календарь', icon: Icons.calendar_today, color: Color(0xFF2196F3), onPressed: () => context.read<NotificationSettingsBloc>().add(TestNotification('calendar'))),
        _TestButton(label: 'Сон', icon: Icons.bedtime, color: Color(0xFF9C27B0), onPressed: () => context.read<NotificationSettingsBloc>().add(TestNotification('sleep'))),
        _TestButton(label: 'Настроение', icon: Icons.mood, color: Color(0xFF4CAF50), onPressed: () => context.read<NotificationSettingsBloc>().add(TestNotification('mood'))),
        _TestButton(label: 'Дневник', icon: Icons.book, color: Color(0xFFFF9800), onPressed: () => context.read<NotificationSettingsBloc>().add(TestNotification('diary'))),
      ]),
    ])));
}

class _CalendarSettings extends StatelessWidget {
  final bool enabled; final int reminderMinutes;
  _CalendarSettings({required this.enabled, required this.reminderMinutes});
  @override Widget build(BuildContext context) => Column(children: [
    _ToggleRow(label: 'Напоминания о событиях', value: enabled, onChanged: (v) => context.read<NotificationSettingsBloc>().add(UpdateCalendarSettings(enabled: v))),
    if (enabled) ...[AppSize.gapH(12), _ReminderMinutesPicker(currentMinutes: reminderMinutes, onChanged: (m) => context.read<NotificationSettingsBloc>().add(UpdateCalendarSettings(reminderMinutes: m)))],
  ]);
}

class _SleepSettings extends StatelessWidget {
  final bool enabled; final TimeOfDay morningTime; final TimeOfDay eveningTime;
  _SleepSettings({required this.enabled, required this.morningTime, required this.eveningTime});
  @override Widget build(BuildContext context) => Column(children: [
    _ToggleRow(label: 'Утренние и вечерние напоминания', value: enabled, onChanged: (v) => context.read<NotificationSettingsBloc>().add(UpdateSleepSettings(enabled: v))),
    if (enabled) ...[AppSize.gapH(12), _TimePickerRow(label: 'Утро', icon: Icons.wb_sunny, time: morningTime, onChanged: (t) => context.read<NotificationSettingsBloc>().add(UpdateSleepSettings(morningTime: t))), AppSize.gapH(8), _TimePickerRow(label: 'Вечер', icon: Icons.nightlight, time: eveningTime, onChanged: (t) => context.read<NotificationSettingsBloc>().add(UpdateSleepSettings(eveningTime: t)))],
  ]);
}

class _MoodSettings extends StatelessWidget {
  final bool enabled; final List<TimeOfDay> reminderTimes;
  _MoodSettings({required this.enabled, required this.reminderTimes});
  @override Widget build(BuildContext context) => Column(children: [
    _ToggleRow(label: 'Напоминания отметить настроение', value: enabled, onChanged: (v) => context.read<NotificationSettingsBloc>().add(UpdateMoodSettings(enabled: v))),
    if (enabled) ...[AppSize.gapH(12),
      ...reminderTimes.asMap().entries.map((e) => Padding(padding: AppSize.paddingOnly(bottom: 8), child: Row(children: [
        Icon(Icons.access_time, size: 16, color: AppColors.mutedForeground), AppSize.gapW(8),
        _TimeButton(time: e.value, onChanged: (t) { final u = List<TimeOfDay>.from(reminderTimes); u[e.key] = t; context.read<NotificationSettingsBloc>().add(UpdateMoodSettings(reminderTimes: u)); }),
        Spacer(), if (reminderTimes.length > 1) IconButton(icon: Icon(Icons.close, size: 18, color: AppColors.mutedForeground), onPressed: () { final u = List<TimeOfDay>.from(reminderTimes); u.removeAt(e.key); context.read<NotificationSettingsBloc>().add(UpdateMoodSettings(reminderTimes: u)); }),
      ]))),
      AppSize.gapH(4), OutlinedButton.icon(onPressed: reminderTimes.length < 5 ? () { final u = List<TimeOfDay>.from(reminderTimes); u.add(TimeOfDay(hour: 18, minute: 0)); context.read<NotificationSettingsBloc>().add(UpdateMoodSettings(reminderTimes: u)); } : null, icon: Icon(Icons.add, size: 16), label: Text('Добавить время'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.citrusOrange, side: BorderSide(color: AppColors.citrusOrange.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)), padding: AppSize.paddingH(12, 8))),
    ],
  ]);
}

class _DiarySettings extends StatelessWidget {
  final bool enabled; final TimeOfDay reminderTime; final bool includeMoodPrompt;
  _DiarySettings({required this.enabled, required this.reminderTime, required this.includeMoodPrompt});
  @override Widget build(BuildContext context) => Column(children: [
    _ToggleRow(label: 'Вечерние напоминания', value: enabled, onChanged: (v) => context.read<NotificationSettingsBloc>().add(UpdateDiarySettings(enabled: v))),
    if (enabled) ...[AppSize.gapH(12), _TimePickerRow(label: 'Время', icon: Icons.edit_note, time: reminderTime, onChanged: (t) => context.read<NotificationSettingsBloc>().add(UpdateDiarySettings(reminderTime: t))), AppSize.gapH(8),
      _ToggleRow(label: 'Предлагать отметить настроение', value: includeMoodPrompt, onChanged: (v) => context.read<NotificationSettingsBloc>().add(UpdateDiarySettings(includeMoodPrompt: v)))],
  ]);
}

class _ToggleRow extends StatelessWidget {
  final String label; final bool value; final ValueChanged<bool> onChanged;
  _ToggleRow({required this.label, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(label, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14)))), Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.citrusGreen)]);
}

class _TimePickerRow extends StatelessWidget {
  final String label; final IconData icon; final TimeOfDay time; final ValueChanged<TimeOfDay> onChanged;
  _TimePickerRow({required this.label, required this.icon, required this.time, required this.onChanged});
  @override Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18, color: AppColors.mutedForeground), AppSize.gapW(8), Text(label, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))), Spacer(), _TimeButton(time: time, onChanged: onChanged)]);
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay time; final ValueChanged<TimeOfDay> onChanged;
  _TimeButton({required this.time, required this.onChanged});
  @override Widget build(BuildContext context) {
    final ts = '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';
    return GestureDetector(onTap: () async { final picked = await showTimePicker(context: context, initialTime: time, builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(timePickerTheme: TimePickerThemeData(backgroundColor: AppColors.surface1)), child: child!)); if (picked != null) onChanged(picked); },
      child: Container(padding: AppSize.paddingH(14, 8), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: AppSize.radius(10), border: Border.all(color: AppColors.subtleBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.access_time, size: 14, color: AppColors.mutedForeground), AppSize.gapW(6), Text(ts, style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]))])));
  }
}

class _ReminderMinutesPicker extends StatelessWidget {
  final int currentMinutes; final ValueChanged<int> onChanged;
  _ReminderMinutesPicker({required this.currentMinutes, required this.onChanged});
  static const _opts = [5, 10, 15, 30, 60];
  @override Widget build(BuildContext context) => Row(children: [Text('За сколько минут:', style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13))), AppSize.gapW(8),
    Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _opts.map((m) { final sel = m == currentMinutes; return Padding(padding: AppSize.paddingOnly(left: 6), child: GestureDetector(onTap: () => onChanged(m), child: Container(padding: AppSize.paddingH(12, 6), decoration: BoxDecoration(color: sel ? AppColors.citrusOrange : AppColors.surface2, borderRadius: AppSize.radius(8), border: Border.all(color: sel ? AppColors.citrusOrange : AppColors.subtleBorder)), child: Text('$m', style: TextStyle(color: sel ? Colors.white : AppColors.mutedForeground, fontSize: AppSize.s(13), fontWeight: sel ? FontWeight.w600 : FontWeight.w400))))); }).toList())))]);
}

class _TestButton extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onPressed;
  _TestButton({required this.label, required this.icon, required this.color, required this.onPressed});
  @override Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 16, color: color), label: Text(label),
    style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: AppSize.radius(12)), padding: AppSize.paddingH(12, 8)));
}
