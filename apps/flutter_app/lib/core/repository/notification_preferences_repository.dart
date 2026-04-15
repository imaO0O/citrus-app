import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/notification_preferences.dart';
import '../../services/notification_service.dart';

/// Репозиторий для работы с настройками уведомлений
class NotificationPreferencesRepository {
  static const String _storageKey = 'notification_preferences';
  final FlutterSecureStorage _storage;
  final NotificationService _notificationService;

  NotificationPreferences? _cachedPreferences;

  /// Доступ к сервису уведомлений
  NotificationService get notificationService => _notificationService;

  NotificationPreferencesRepository({
    FlutterSecureStorage? storage,
    NotificationService? notificationService,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _notificationService = notificationService ?? NotificationService();

  /// Получить текущие настройки
  Future<NotificationPreferences> getPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedPreferences = NotificationPreferences.fromJson(json);
        return _cachedPreferences!;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки настроек уведомлений: $e');
    }

    // Возвращаем настройки по умолчанию
    return const NotificationPreferences();
  }

  /// Сохранить настройки
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final jsonStr = jsonEncode(preferences.toJson());
      await _storage.write(key: _storageKey, value: jsonStr);
      _cachedPreferences = preferences;

      // Применяем настройки к уведомлениям
      await _applyPreferences(preferences);
    } catch (e) {
      debugPrint('Ошибка сохранения настроек уведомлений: $e');
      throw Exception('Не удалось сохранить настройки уведомлений');
    }
  }

  /// Обновить отдельные настройки
  Future<void> updatePreferences({
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
  }) async {
    final current = await getPreferences();
    final updated = current.copyWith(
      calendarNotificationsEnabled: calendarNotificationsEnabled,
      calendarReminderMinutes: calendarReminderMinutes,
      sleepRemindersEnabled: sleepRemindersEnabled,
      sleepMorningTime: sleepMorningTime,
      sleepEveningTime: sleepEveningTime,
      moodRemindersEnabled: moodRemindersEnabled,
      moodReminderTimes: moodReminderTimes,
      diaryRemindersEnabled: diaryRemindersEnabled,
      diaryReminderTime: diaryReminderTime,
      diaryIncludeMoodPrompt: diaryIncludeMoodPrompt,
    );
    await savePreferences(updated);
  }

  /// Применить настройки к уведомлениям
  Future<void> _applyPreferences(NotificationPreferences prefs) async {
    // Инициализируем сервис
    await _notificationService.initialize();

    // Настройка уведомлений о сне
    if (prefs.sleepRemindersEnabled) {
      await _notificationService.enableSleepReminders(
        morningTime: prefs.sleepMorningTime,
        eveningTime: prefs.sleepEveningTime,
      );
    } else {
      await _notificationService.disableSleepReminders();
    }

    // Настройка уведомлений о настроении
    if (prefs.moodRemindersEnabled) {
      await _notificationService.enableMoodReminders(
        times: prefs.moodReminderTimes,
      );
    } else {
      await _notificationService.disableMoodReminders();
    }

    // Настройка уведомлений о дневнике
    if (prefs.diaryRemindersEnabled) {
      await _notificationService.enableDiaryReminders(
        time: prefs.diaryReminderTime,
        includeMoodPrompt: prefs.diaryIncludeMoodPrompt,
      );
    } else {
      await _notificationService.disableDiaryReminders();
    }
  }

  /// Запланировать уведомление о событии календаря
  Future<void> scheduleCalendarEventNotification({
    required String eventId,
    required String title,
    required String? description,
    required DateTime eventDate,
    required TimeOfDay? eventTime,
  }) async {
    final prefs = await getPreferences();
    if (!prefs.calendarNotificationsEnabled) return;

    // Генерируем числовой ID из строки eventId
    final id = eventId.hashCode.abs();

    await _notificationService.scheduleCalendarEvent(
      id: id,
      title: title,
      description: description,
      eventDate: eventDate,
      eventTime: eventTime,
      minutesBefore: prefs.calendarReminderMinutes,
    );
  }

  /// Отменить уведомление о событии календаря
  Future<void> cancelCalendarEventNotification(String eventId) async {
    final id = eventId.hashCode.abs();
    await _notificationService.cancelCalendarEvent(id);
  }

  /// Обновить уведомления для всех событий календаря
  Future<void> updateCalendarNotifications(
    List<CalendarEventInfo> events,
  ) async {
    final prefs = await getPreferences();
    if (!prefs.calendarNotificationsEnabled) {
      // Отменяем все уведомления календаря
      for (final event in events) {
        await cancelCalendarEventNotification(event.id);
      }
      return;
    }

    // Обновляем уведомления
    for (final event in events) {
      if (event.notificationEnabled) {
        await scheduleCalendarEventNotification(
          eventId: event.id,
          title: event.title,
          description: event.description,
          eventDate: event.eventDate,
          eventTime: event.eventTime,
        );
      } else {
        await cancelCalendarEventNotification(event.id);
      }
    }
  }

  /// Проверить, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Запросить разрешения на уведомления
  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissions();
  }

  /// Очистить кэш
  void clearCache() {
    _cachedPreferences = null;
  }
}

/// Информация о событии для уведомлений
class CalendarEventInfo {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final TimeOfDay? eventTime;
  final bool notificationEnabled;

  CalendarEventInfo({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    required this.notificationEnabled,
  });
}
