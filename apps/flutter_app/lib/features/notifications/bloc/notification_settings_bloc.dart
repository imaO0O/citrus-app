import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/notification_preferences.dart';
import '../../../core/repository/notification_preferences_repository.dart';

// ==================== СОБЫТИЯ ====================

abstract class NotificationSettingsEvent {
  const NotificationSettingsEvent();
}

class LoadNotificationSettings extends NotificationSettingsEvent {
  const LoadNotificationSettings();
}

class UpdateCalendarSettings extends NotificationSettingsEvent {
  final bool? enabled;
  final int? reminderMinutes;
  const UpdateCalendarSettings({this.enabled, this.reminderMinutes});
}

class UpdateSleepSettings extends NotificationSettingsEvent {
  final bool? enabled;
  final TimeOfDay? morningTime;
  final TimeOfDay? eveningTime;
  const UpdateSleepSettings({
    this.enabled,
    this.morningTime,
    this.eveningTime,
  });
}

class UpdateMoodSettings extends NotificationSettingsEvent {
  final bool? enabled;
  final List<TimeOfDay>? reminderTimes;
  const UpdateMoodSettings({this.enabled, this.reminderTimes});
}

class UpdateDiarySettings extends NotificationSettingsEvent {
  final bool? enabled;
  final TimeOfDay? reminderTime;
  final bool? includeMoodPrompt;
  const UpdateDiarySettings({
    this.enabled,
    this.reminderTime,
    this.includeMoodPrompt,
  });
}

class RequestNotificationPermissions extends NotificationSettingsEvent {
  const RequestNotificationPermissions();
}

class TestNotification extends NotificationSettingsEvent {
  final String type; // 'calendar', 'sleep', 'mood', 'diary'
  const TestNotification(this.type);
}

// ==================== СОСТОЯНИЯ ====================

abstract class NotificationSettingsState {
  const NotificationSettingsState();
}

class NotificationSettingsInitial extends NotificationSettingsState {
  const NotificationSettingsInitial();
}

class NotificationSettingsLoading extends NotificationSettingsState {
  const NotificationSettingsLoading();
}

class NotificationSettingsLoaded extends NotificationSettingsState {
  final NotificationPreferences preferences;
  final bool permissionsGranted;

  const NotificationSettingsLoaded({
    required this.preferences,
    required this.permissionsGranted,
  });

  NotificationSettingsLoaded copyWith({
    NotificationPreferences? preferences,
    bool? permissionsGranted,
  }) {
    return NotificationSettingsLoaded(
      preferences: preferences ?? this.preferences,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
    );
  }
}

class NotificationSettingsError extends NotificationSettingsState {
  final String message;
  const NotificationSettingsError(this.message);
}

// ==================== BLOC ====================

class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  final NotificationPreferencesRepository _repository;

  NotificationSettingsBloc({
    required NotificationPreferencesRepository repository,
  })  : _repository = repository,
        super(const NotificationSettingsInitial()) {
    on<LoadNotificationSettings>(_onLoadSettings);
    on<UpdateCalendarSettings>(_onUpdateCalendar);
    on<UpdateSleepSettings>(_onUpdateSleep);
    on<UpdateMoodSettings>(_onUpdateMood);
    on<UpdateDiarySettings>(_onUpdateDiary);
    on<RequestNotificationPermissions>(_onRequestPermissions);
    on<TestNotification>(_onTestNotification);
  }

  Future<void> _onLoadSettings(
    LoadNotificationSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(const NotificationSettingsLoading());
    try {
      final prefs = await _repository.getPreferences();
      final permissionsGranted = await _repository.areNotificationsEnabled();
      emit(NotificationSettingsLoaded(
        preferences: prefs,
        permissionsGranted: permissionsGranted,
      ));
    } catch (e) {
      emit(NotificationSettingsError('Ошибка загрузки настроек: $e'));
    }
  }

  Future<void> _onUpdateCalendar(
    UpdateCalendarSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    try {
      await _repository.updatePreferences(
        calendarNotificationsEnabled: event.enabled,
        calendarReminderMinutes: event.reminderMinutes,
      );
      final prefs = await _repository.getPreferences();
      emit(currentState.copyWith(preferences: prefs));
    } catch (e) {
      emit(NotificationSettingsError('Ошибка обновления настроек календаря: $e'));
      emit(currentState);
    }
  }

  Future<void> _onUpdateSleep(
    UpdateSleepSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    try {
      await _repository.updatePreferences(
        sleepRemindersEnabled: event.enabled,
        sleepMorningTime: event.morningTime,
        sleepEveningTime: event.eveningTime,
      );
      final prefs = await _repository.getPreferences();
      emit(currentState.copyWith(preferences: prefs));
    } catch (e) {
      emit(NotificationSettingsError('Ошибка обновления настроек сна: $e'));
      emit(currentState);
    }
  }

  Future<void> _onUpdateMood(
    UpdateMoodSettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    try {
      await _repository.updatePreferences(
        moodRemindersEnabled: event.enabled,
        moodReminderTimes: event.reminderTimes,
      );
      final prefs = await _repository.getPreferences();
      emit(currentState.copyWith(preferences: prefs));
    } catch (e) {
      emit(NotificationSettingsError('Ошибка обновления настроек настроения: $e'));
      emit(currentState);
    }
  }

  Future<void> _onUpdateDiary(
    UpdateDiarySettings event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    try {
      await _repository.updatePreferences(
        diaryRemindersEnabled: event.enabled,
        diaryReminderTime: event.reminderTime,
        diaryIncludeMoodPrompt: event.includeMoodPrompt,
      );
      final prefs = await _repository.getPreferences();
      emit(currentState.copyWith(preferences: prefs));
    } catch (e) {
      emit(NotificationSettingsError('Ошибка обновления настроек дневника: $e'));
      emit(currentState);
    }
  }

  Future<void> _onRequestPermissions(
    RequestNotificationPermissions event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    try {
      final granted = await _repository.requestPermissions();
      emit(currentState.copyWith(permissionsGranted: granted));
    } catch (e) {
      debugPrint('Ошибка запроса разрешений: $e');
    }
  }

  Future<void> _onTestNotification(
    TestNotification event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    if (state is! NotificationSettingsLoaded) return;

    final currentState = state as NotificationSettingsLoaded;
    final notificationService = _repository.notificationService;

    try {
      switch (event.type) {
        case 'calendar':
          await notificationService.showInstantNotification(
            title: '📅 Тест: Событие календаря',
            body: 'Ваше событие начинается через 15 минут',
          );
          break;
        case 'sleep':
          await notificationService.showInstant