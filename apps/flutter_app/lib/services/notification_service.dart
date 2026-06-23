import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Сервис для управления локальными уведомлениями
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ID каналов уведомлений
  static const String _calendarChannelId = 'calendar_events';
  static const String _sleepChannelId = 'sleep_reminders';
  static const String _moodChannelId = 'mood_reminders';
  static const String _diaryChannelId = 'diary_reminders';

  // ID уведомлений (для ежедневных напоминаний)
  static const int _sleepMorningReminderId = 1001;
  static const int _sleepEveningReminderId = 1002;
  static const int _moodReminderId = 2001;
  static const int _diaryReminderId = 3001;
  static const int _inactivityReminderId = 4001;
  static const int _courseReminderId = 5001;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (kIsWeb) {
      // На вебе локальные уведомления (flutter_local_notifications) недоступны.
      _initialized = true;
      return;
    }
    if (_initialized) {
      debugPrint('NotificationService: уже инициализирован');
      return;
    }

    debugPrint('NotificationService: начало инициализации...');

    // Инициализация timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
    debugPrint('NotificationService: timezone инициализирован');

    // Настройки для Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Создаём каналы уведомлений для Android
    await _createNotificationChannels();

    _initialized = true;
    debugPrint('NotificationService: инициализация завершена');
  }

  /// Создание каналов уведомлений (Android)
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Канал для событий календаря
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _calendarChannelId,
        'События календаря',
        description: 'Уведомления о предстоящих событиях в календаре',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Канал для напоминаний о сне
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _sleepChannelId,
        'Напоминания о сне',
        description: 'Утренние и вечерние напоминания отметить сон',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Канал для напоминаний о настроении
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _moodChannelId,
        'Напоминания о настроении',
        description: 'Напоминания отметить своё настроение',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Канал для напоминаний о дневнике
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _diaryChannelId,
        'Напоминания о дневнике',
        description: 'Вечерние напоминания сделать запись в дневнике',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  /// Запрос разрешений на уведомления
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    debugPrint('NotificationService: запрос разрешений...');
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final enabled = await androidPlugin.areNotificationsEnabled();
      debugPrint('NotificationService: уведомления включены? $enabled');
      
      if (enabled != true) {
        debugPrint('NotificationService: запрашиваем разрешение...');
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('NotificationService: разрешение получено? $granted');
        return granted ?? false;
      }
      return true;
    }

    // Для iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Проверка, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    return _initialized;
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTap(NotificationResponse response) {
    // Здесь можно добавить навигацию на соответствующий экран
    debugPrint('Уведомление нажато: ${response.payload}');
  }

  // ==================== КАЛЕНДАРЬ ====================

  /// Запланировать уведомление о событии календаря
  Future<void> scheduleCalendarEvent({
    required int id,
    required String title,
    required String? description,
    required DateTime eventDate,
    required TimeOfDay? eventTime,
    required int minutesBefore,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    // Вычисляем время уведомления
    var scheduledDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      eventTime?.hour ?? 9,
      eventTime?.minute ?? 0,
    );

    // Отнимаем время до события
    scheduledDate = scheduledDate.subtract(Duration(minutes: minutesBefore));

    // Если время уже прошло, не планируем
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      '⏰ $title',
      description ?? 'Событие начинается ${minutesBefore}мин',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _calendarChannelId,
          'События календаря',
          channelDescription: 'Уведомления о предстоящих событиях',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2196F3),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'calendar_event_$id',
    );
  }

  /// Отменить уведомление о событии календаря
  Future<void> cancelCalendarEvent(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  // ==================== СОН ====================

  /// Включить ежедневные напоминания о сне
  Future<void> enableSleepReminders({
    required TimeOfDay morningTime, // Напоминание отметить утреннее пробуждение
    required TimeOfDay eveningTime, // Напоминание отметить время сна
  }) async {
    if (!_initialized) await initialize();

    // Утреннее напоминание (например, в 9:00 - "Как вы спали?")
    await _scheduleDailyReminder(
      id: _sleepMorningReminderId,
      title: '😴 Как вы спали?',
      body: 'Не забудьте отметить время пробуждения и качество сна',
      hour: morningTime.hour,
      minute: morningTime.minute,
      channelId: _sleepChannelId,
      channelName: 'Напоминания о сне',
      payload: 'sleep_morning',
    );

    // Вечернее напоминание (например, в 22:00 - "Пора спать?")
    await _scheduleDailyReminder(
      id: _sleepEveningReminderId,
      title: '🌙 Пора отметить сон',
      body: 'Не забудьте отметить время, когда вы легли спать',
      hour: eveningTime.hour,
      minute: eveningTime.minute,
      channelId: _sleepChannelId,
      channelName: 'Напоминания о сне',
      payload: 'sleep_evening',
    );
  }

  /// Отключить напоминания о сне
  Future<void> disableSleepReminders() async {
    if (kIsWeb) return;
    await _notifications.cancel(_sleepMorningReminderId);
    await _notifications.cancel(_sleepEveningReminderId);
  }

  // ==================== НАСТРОЕНИЕ ====================

  /// Включить ежедневные напоминания о настроении
  Future<void> enableMoodReminders({
    required List<TimeOfDay> times, // Несколько раз в день
  }) async {
    if (!_initialized) await initialize();

    // Отменяем старые напоминания
    await disableMoodReminders();

    // Создаём новые напоминания для каждого времени
    for (int i = 0; i < times.length; i++) {
      final messages = [
        '😊 Как ваше настроение?',
        '🌈 Проверьте своё настроение',
        '💭 Как вы себя чувствуете?',
      ];
      final bodies = [
        'Сделайте быструю отметку о своём настроении',
        'Отметьте своё настроение, чтобы отслеживать динамику',
        'Важно следить за эмоциональным состоянием',
      ];

      await _scheduleDailyReminder(
        id: _moodReminderId + i,
        title: messages[i % messages.length],
        body: bodies[i % bodies.length],
        hour: times[i].hour,
        minute: times[i].minute,
        channelId: _moodChannelId,
        channelName: 'Напоминания о настроении',
        payload: 'mood_check',
      );
    }
  }

  /// Отключить напоминания о настроении
  Future<void> disableMoodReminders() async {
    if (kIsWeb) return;
    for (int i = 0; i < 5; i++) {
      await _notifications.cancel(_moodReminderId + i);
    }
  }

  // ==================== ДНЕВНИК ====================

  /// Включить вечерние напоминания о дневнике
  Future<void> enableDiaryReminders({
    required TimeOfDay time,
    required bool includeMoodPrompt, // Предлагать отметить настроение
  }) async {
    if (!_initialized) await initialize();

    final title = includeMoodPrompt
        ? '📝 Как прошёл ваш день?'
        : '📝 Время для дневника';
    final body = includeMoodPrompt
        ? 'Запишите свои мысли и отметьте настроение'
        : 'Сделайте запись о том, как прошёл день';

    await _scheduleDailyReminder(
      id: _diaryReminderId,
      title: title,
      body: body,
      hour: time.hour,
      minute: time.minute,
      channelId: _diaryChannelId,
      channelName: 'Напоминания о дневнике',
      payload: 'diary_evening',
    );
  }

  /// Отключить напоминания о дневнике
  Future<void> disableDiaryReminders() async {
    if (kIsWeb) return;
    await _notifications.cancel(_diaryReminderId);
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Запланировать ежедневное напоминание
  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String payload,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Если время уже прошло, планируем на завтра
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: _getChannelColor(channelId),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Ежедневное повторение
      payload: payload,
    );
  }

  /// Разовое уведомление на конкретное время (без повторения).
  Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required String channelId,
    required String channelName,
    required String payload,
  }) async {
    if (kIsWeb) return;
    if (when.isBefore(DateTime.now())) return;
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: _getChannelColor(channelId),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Мягкий «соскучились»: сработает, только если приложение не открывали
  /// [afterDays] дней. Вызывается при каждом открытии — переносит срок вперёд,
  /// поэтому активным пользователям не приходит.
  Future<void> scheduleInactivityNudge({int afterDays = 3}) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();
    await _notifications.cancel(_inactivityReminderId);
    final when = DateTime.now().add(Duration(days: afterDays));
    await _scheduleOnce(
      id: _inactivityReminderId,
      title: 'Как ты? 🍊',
      body: 'Давно не виделись. Удели себе минутку — отметь настроение.',
      when: DateTime(when.year, when.month, when.day, 18, 0),
      channelId: _moodChannelId,
      channelName: 'Напоминания о настроении',
      payload: 'inactivity',
    );
  }

  /// Напоминание, что в курсе открылся новый день (на дату [when], утром).
  Future<void> scheduleCourseDayUnlock({
    required String courseTitle,
    required DateTime when,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();
    await _notifications.cancel(_courseReminderId);
    await _scheduleOnce(
      id: _courseReminderId,
      title: 'Новый день курса открыт 🎓',
      body: 'Курс «$courseTitle» ждёт — продолжи, пока на волне.',
      when: DateTime(when.year, when.month, when.day, 10, 0),
      channelId: _moodChannelId,
      channelName: 'Напоминания о настроении',
      payload: 'course_unlock',
    );
  }

  /// Получить цвет для канала
  Color _getChannelColor(String channelId) {
    return switch (channelId) {
      _calendarChannelId => const Color(0xFF2196F3),
      _sleepChannelId => const Color(0xFF9C27B0),
      _moodChannelId => const Color(0xFF4CAF50),
      _diaryChannelId => const Color(0xFFFF9800),
      _ => const Color(0xFF607D8B),
    };
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  /// Получить список запланированных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Показать мгновенное уведомление
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String channelId = 'instant',
  }) async {
    if (kIsWeb) return;
    debugPrint('NotificationService: показ уведомления - $title');
    
    if (!_initialized) {
      debugPrint('NotificationService: требуется инициализация...');
      await initialize();
    }

    // Определяем название канала и цвет на основе channelId
    final (channelName, color) = switch (channelId) {
      'calendar' => ('События календаря', const Color(0xFF2196F3)),
      'sleep' => ('Напоминания о сне', const Color(0xFF9C27B0)),
      'mood' => ('Напоминания о настроении', const Color(0xFF4CAF50)),
      'diary' => ('Напоминания о дневнике', const Color(0xFFFF9800)),
      _ => ('Мгновенные уведомления', const Color(0xFF607D8B)),
    };

    try {
      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId == 'instant' ? 'instant' : _getChannelIdByName(channelId),
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: color,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      debugPrint('NotificationService: уведомление показано успешно');
    } catch (e, stackTrace) {
      debugPrint('NotificationService: ОШИБКА показа уведомления: $e');
      debugPrint('NotificationService: StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Получить ID канала по короткому имени
  String _getChannelIdByName(String name) {
    return switch (name) {
      'calendar' => _calendarChannelId,
      'sleep' => _sleepChannelId,
      'mood' => _moodChannelId,
      'diary' => _diaryChannelId,
      _ => _calendarChannelId,
    };
  }
}
