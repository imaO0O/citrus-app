import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/calendar_event.dart';
import '../../../core/repository/calendar_event_repository.dart';
import '../../../core/repository/mood_repository.dart';
import '../../../core/repository/notification_preferences_repository.dart';

// События
abstract class CalendarEvent {
  const CalendarEvent();
}

class LoadCalendar extends CalendarEvent {
  final DateTime month;
  const LoadCalendar({required this.month});
}

class AddEvent extends CalendarEvent {
  final CalendarEventModel event;
  const AddEvent(this.event);
}

class UpdateEvent extends CalendarEvent {
  final CalendarEventModel event;
  const UpdateEvent(this.event);
}

class DeleteEvent extends CalendarEvent {
  final String eventId;
  const DeleteEvent(this.eventId);
}

class SelectDay extends CalendarEvent {
  final DateTime day;
  const SelectDay(this.day);
}

// Состояния
abstract class CalendarState {
  const CalendarState();
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final Map<DateTime, List<CalendarEventModel>> events;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Map<DateTime, double> moodAverages;

  const CalendarLoaded({
    required this.events,
    required this.selectedDay,
    required this.focusedDay,
    this.moodAverages = const {},
  });

  List<CalendarEventModel> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }

  /// Получить уникальные события месяца (повторяющиеся — один раз).
  List<CalendarEventModel> getEventsForMonth(DateTime month) {
    final seen = <String>{};
    final unique = <CalendarEventModel>[];
    for (final e in events.values.expand((e) => e)) {
      if (seen.add(e.id)) unique.add(e);
    }
    unique.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return unique;
  }

  /// Получить все события (отсортированные по дате)
  List<CalendarEventModel> getAllEvents() {
    final allEvents = events.values.expand((e) => e).toList();
    allEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return allEvents;
  }
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
}

// BLoC
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarEventRepository _repository;
  final MoodRepository _moodRepository;
  final NotificationPreferencesRepository _notificationRepository;

  CalendarBloc({
    required CalendarEventRepository repository,
    required MoodRepository moodRepository,
    NotificationPreferencesRepository? notificationRepository,
  })  : _repository = repository,
        _moodRepository = moodRepository,
        _notificationRepository = notificationRepository ?? NotificationPreferencesRepository(),
        super(CalendarInitial()) {
    on<LoadCalendar>(_onLoadCalendar);
    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<SelectDay>(_onSelectDay);
  }

  /// Обновить userId и перезагрузить календарь
  void updateUserId(String newUserId, {String? token}) {
    debugPrint('CalendarBloc: обновление userId на $newUserId');
    debugPrint('  - получен token: ${token != null ? "length=${token.length}" : "null"}');
    _repository.setUserId(newUserId, token: token);
    // Очищаем состояние
    emit(const CalendarInitial());
    // Загружаем события для нового пользователя
    add(LoadCalendar(month: DateTime.now()));
  }

  Future<void> _onLoadCalendar(
    LoadCalendar event,
    Emitter<CalendarState> emit,
  ) async {
    debugPrint('CalendarBloc: загрузка календаря для userId=${_repository.userId}, месяц=${event.month}');
    emit(const CalendarLoading());

    try {
      final events = await _repository.getEventsForMonth(event.month);
      debugPrint('CalendarBloc: загружено ${events.length} событий');

      // Группируем события по дням, разворачивая повторяющиеся в даты текущего месяца
      final Map<DateTime, List<CalendarEventModel>> eventsByDay = {};
      for (final ev in events) {
        for (final day in _occurrencesInMonth(ev, event.month)) {
          eventsByDay.putIfAbsent(day, () => []).add(ev);
        }
      }
      debugPrint('CalendarBloc: сгруппировано по ${eventsByDay.length} дням');

      // Загружаем средние настроения по дням для всего месяца
      final monthStart = DateTime(event.month.year, event.month.month, 1);
      final monthEnd = DateTime(event.month.year, event.month.month + 1, 0);
      final moodAverages = await _moodRepository.getAverageMoodByDay(
        startDate: monthStart,
        endDate: monthEnd,
      );
      debugPrint('CalendarBloc: загружены данные настроения для ${moodAverages.length} дней');

      final now = DateTime.now();
      emit(CalendarLoaded(
        events: eventsByDay,
        selectedDay: now,
        focusedDay: now,
        moodAverages: moodAverages,
      ));

      // Перепланируем уведомления для загруженных событий
      try {
        final eventInfos = events
            .where((e) => e.notificationEnabled && e.startTime != null)
            .map((e) => CalendarEventInfo(
                  id: e.id,
                  title: e.title,
                  description: e.description,
                  eventDate: e.eventDate,
                  eventTime: _parseTime(e.startTime),
                  notificationEnabled: e.notificationEnabled,
                ))
            .toList();
        await _notificationRepository.updateCalendarNotifications(eventInfos);
      } catch (e) {
        debugPrint('CalendarBloc: ошибка перепланирования уведомлений: $e');
      }
    } catch (e) {
      debugPrint('CalendarBloc: ошибка загрузки: $e');
      emit(CalendarError('Ошибка загрузки календаря: $e'));
    }
  }

  Future<void> _onAddEvent(
    AddEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final createdEvent = await _repository.createEvent(event.event);

      // Планируем уведомление для события с включенными уведомлениями
      if (createdEvent.notificationEnabled && createdEvent.startTime != null) {
        await _notificationRepository.scheduleCalendarEventNotification(
          eventId: createdEvent.id,
          title: createdEvent.title,
          description: createdEvent.description,
          eventDate: createdEvent.eventDate,
          eventTime: _parseTime(createdEvent.startTime),
        );
      }
        
      if (state is CalendarLoaded) {
        final loadedState = state as CalendarLoaded;
        final day = DateTime(
          event.event.eventDate.year,
          event.event.eventDate.month,
          event.event.eventDate.day,
        );
        
        final updatedEvents = Map<DateTime, List<CalendarEventModel>>.from(loadedState.events);
        updatedEvents.putIfAbsent(day, () => []).add(createdEvent);
        
        emit(CalendarLoaded(
          events: updatedEvents,
          selectedDay: loadedState.selectedDay,
          focusedDay: loadedState.focusedDay,
          moodAverages: loadedState.moodAverages,
        ));
      }
    } catch (e) {
      emit(CalendarError('Ошибка добавления события: $e'));
    }
  }

  /// Даты, на которые приходится событие в указанном месяце (с учётом повтора).
  List<DateTime> _occurrencesInMonth(CalendarEventModel e, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final base = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
    final result = <DateTime>[];

    if (e.recurrence == 'none' || e.recurrence.isEmpty) {
      if (!base.isBefore(monthStart) && !base.isAfter(monthEnd)) result.add(base);
      return result;
    }

    for (DateTime d = monthStart.isAfter(base) ? monthStart : base;
        !d.isAfter(monthEnd);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.isBefore(base)) continue;
      final diff = d.difference(base).inDays;
      bool match;
      switch (e.recurrence) {
        case 'daily':
          match = true;
          break;
        case 'weekly':
          match = diff % 7 == 0;
          break;
        case 'monthly':
          match = d.day == base.day;
          break;
        default:
          match = d.isAtSameMomentAs(base);
      }
      if (match) result.add(DateTime(d.year, d.month, d.day));
    }
    return result;
  }

  /// Парсит строку времени в TimeOfDay
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _repository.updateEvent(event.event);

      // Обновляем уведомление для события
      if (event.event.notificationEnabled && event.event.startTime != null) {
        await _notificationRepository.scheduleCalendarEventNotification(
          eventId: event.event.id,
          title: event.event.title,
          description: event.event.description,
          eventDate: event.event.eventDate,
          eventTime: _parseTime(event.event.startTime),
        );
      } else {
        // Если уведомления отключены - отменяем
        await _notificationRepository.cancelCalendarEventNotification(event.event.id);
      }

      // Перезагружаем события из БД после обновления
      if (state is CalendarLoaded) {
        final loadedState = state as CalendarLoaded;
        add(LoadCalendar(month: loadedState.focusedDay));
      }
    } catch (e) {
      emit(CalendarError('Ошибка обновления события: $e'));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<CalendarState> emit,
  ) async {
    final previousState = state;
    try {
      await _repository.deleteEvent(event.eventId);

      // Отменяем уведомление для удалённого события (не критично — не должно
      // ронять успешное удаление, если на устройстве нет разрешения).
      try {
        await _notificationRepository.cancelCalendarEventNotification(event.eventId);
      } catch (e) {
        debugPrint('CalendarBloc: не удалось отменить уведомление: $e');
      }

      if (previousState is CalendarLoaded) {
        // Глубокая копия: пересоздаём внутренние списки, чтобы не мутировать
        // предыдущее состояние (иначе BlocListener мог не сработать).
        final updatedEvents = <DateTime, List<CalendarEventModel>>{};
        for (final entry in previousState.events.entries) {
          final filtered = entry.value
              .where((e) => e.id != event.eventId)
              .toList();
          if (filtered.isNotEmpty) {
            updatedEvents[entry.key] = filtered;
          }
        }

        emit(CalendarLoaded(
          events: updatedEvents,
          selectedDay: previousState.selectedDay,
          focusedDay: previousState.focusedDay,
          moodAverages: previousState.moodAverages,
        ));
      }
    } catch (e) {
      debugPrint('CalendarBloc: ошибка удаления события: $e');
      // Не затираем загруженный календарь экраном ошибки — иначе пользователь
      // теряет все события. Перезагружаем месяц, чтобы UI остался в согласии
      // с сервером: если удаление не прошло, событие останется видимым.
      if (previousState is CalendarLoaded) {
        add(LoadCalendar(month: previousState.focusedDay));
      } else {
        emit(CalendarError('Ошибка удаления события: $e'));
      }
    }
  }

  void _onSelectDay(
    SelectDay event,
    Emitter<CalendarState> emit,
  ) {
    if (state is CalendarLoaded) {
      final loadedState = state as CalendarLoaded;
      emit(CalendarLoaded(
        events: loadedState.events,
        selectedDay: event.day,
        focusedDay: loadedState.focusedDay,
        moodAverages: loadedState.moodAverages,
      ));
    }
  }
}
