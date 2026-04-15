import 'package:flutter/material.dart';

/// Модель настроек персонализированных уведомлений
class NotificationPreferences {
  // Календарь
  final bool calendarNotificationsEnabled;
  final int calendarReminderMinutes; // За сколько минут до события

  // Сон
  final bool sleepRemindersEnabled;
  final TimeOfDay sleepMorningTime; // Время утреннего напоминания
  final TimeOfDay sleepEveningTime; // Время вечернего напоминания

  // Настроение
  final bool moodRemindersEnabled;
  final List<TimeOfDay> moodReminderTimes; // Времена напоминаний

  // Дневник
  final bool diaryRemindersEnabled;
  final TimeOfDay diaryReminderTime; // Время вечернего напоминания
  final bool diaryIncludeMoodPrompt; // Предлагать отметить настроение

  const NotificationPreferences({
    this.calendarNotificationsEnabled = true,
    this.calendarReminderMinutes = 15,
    this.sleepRemindersEnabled = true,
    this.sleepMorningTime = const TimeOfDay(hour: 9, minute: 0),
    this.sleepEveningTime = const TimeOfDay(hour: 22, minute: 0),
    this.moodRemindersEnabled = true,
    this.moodReminderTimes = const [
      TimeOfDay(hour: 10, minute: 0),
      TimeOfDay(hour: 16, minute: 0),
      TimeOfDay(hour: 20, minute: 0),
    ],
    this.diaryRemindersEnabled = true,
    this.diaryReminderTime = const TimeOfDay(hour: 21, minute: 0),
    this.diaryIncludeMoodPrompt = true,
  });

  /// Создать копию с изменёнными полями
  NotificationPreferences copyWith({
    bool? calendarNotificationsEnabled,
    int? calendarReminderMinutes,
    bool? sleepRemindersEnabled,
    TimeOfDay? sleepMorningTime,
    TimeOfDay? sleepEveningTime,
    bool? moodRemindersEnabled,
    List<TimeOfDay>? moodReminderTimes,
    bool? diaryRemindersEnabled,
    TimeOfDay? diaryReminderTime,
    bool? diaryIncludeMoodPrompt,
  }) {
    return NotificationPreferences(
      calendarNotificationsEnabled:
          calendarNotificationsEnabled ?? this.calendarNotificationsEnabled,
      calendarReminderMinutes:
          calendarReminderMinutes ?? this.calendarReminderMinutes,
      sleepRemindersEnabled:
          sleepRemindersEnabled ?? this.sleepRemindersEnabled,
      sleepMorningTime: sleepMorningTime ?? this.sleepMorningTime,
      sleepEveningTime: sleepEveningTime ?? this.sleepEveningTime,
      moodRemindersEnabled:
          moodRemindersEnabled ?? this.moodRemindersEnabled,
      moodReminderTimes: moodReminderTimes ?? this.moodReminderTimes,
      diaryRemindersEnabled:
          diaryRemindersEnabled ?? this.diaryRemindersEnabled,
      diaryReminderTime: diaryReminderTime ?? this.diaryReminderTime,
      diaryIncludeMoodPrompt:
          diaryIncludeMoodPrompt ?? this.diaryIncludeMoodPrompt,
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() {
    return {
      'calendar_notifications_enabled': calendarNotificationsEnabled,
      'calendar_reminder_minutes': calendarReminderMinutes,
      'sleep_reminders_enabled': sleepRemindersEnabled,
      'sleep_morning_time': '${sleepMorningTime.hour}:${sleepMorningTime.minute}',
      'sleep_evening_time': '${sleepEveningTime.hour}:${sleepEveningTime.minute}',
      'mood_reminders_enabled': moodRemindersEnabled,
      'mood_reminder_times': moodReminderTimes
          .map((t) => '${t.hour}:${t.minute}')
          .toList(),
      'diary_reminders_enabled': diaryRemindersEnabled,
      'diary_reminder_time': '${diaryReminderTime.hour}:${diaryReminderTime.minute}',
      'diary_include_mood_prompt': diaryIncludeMoodPrompt,
    };
  }

  /// Создать из JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    List<TimeOfDay> parseTimes(List<dynamic> times) {
      return times.map((t) => parseTime(t as String)).toList();
    }

    return NotificationPreferences(
      calendarNotificationsEnabled:
          json['calendar_notifications_enabled'] ?? true,
      calendarReminderMinutes: json['calendar_reminder_minutes'] ?? 15,
      sleepRemindersEnabled: json['sleep_reminders_enabled'] ?? true,
      sleepMorningTime: json['sleep_morning_time'] != null
          ? parseTime(json['sleep_morning_time'])
          : const TimeOfDay(hour: 9, minute: 0),
      sleepEveningTime: json['sleep_evening_time'] != null
          ? parseTime(json['sleep_evening_time'])
          : const TimeOfDay(hour: 22, minute: 0),
      moodRemindersEnabled: json['mood_reminders_enabled'] ?? true,
      moodReminderTimes: json['mood_reminder_times'] != null
          ? parseTimes(json['mood_reminder_times'])
          : const [
              TimeOfDay(hour: 10, minute: 0),
              TimeOfDay(hour: 16, minute: 0),
              TimeOfDay(hour: 20, minute: 0),
            ],
      diaryRemindersEnabled: json['diary_reminders_enabled'] ?? true,
      diaryReminderTime: json['diary_reminder_time'] != null
          ? parseTime(json['diary_reminder_time'])
          : const TimeOfDay(hour: 21, minute: 0),
      diaryIncludeMoodPrompt: json['diary_include_mood_prompt'] ?? true,
    );
  }
}
