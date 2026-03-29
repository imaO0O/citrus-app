import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/calendar_event.dart';

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

  const CalendarLoaded({
    required this.events,
    required this.selectedDay,
    required this.focusedDay,
  });

  List<CalendarEventModel> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
}

// BLoC
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  // Временное хранилище событий (в памяти)
  final Map<DateTime, List<CalendarEventModel>> _events = {};

  CalendarBloc() : super(const CalendarInitial()) {
    on<LoadCalendar>(_onLoadCalendar);
    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<SelectDay>(_onSelectDay);
  }

  Future<void> _onLoadCalendar(
    LoadCalendar event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());
    
    try {
      // TODO: Загрузка событий из API
      // Пока используем тестовые данные
      await Future.delayed(const Duration(milliseconds: 300));
      
      final now = DateTime.now();
      final testEvents = [
        CalendarEventModel(
          id: '1',
          userId: 'user1',
          title: 'Прием у терапевта',
          description: 'Плановый осмотр',
          eventDate: DateTime(now.year, now.month, now.day, 10, 0),
          startTime: '10:00:00',
          endTime: '11:00:00',
          notificationEnabled: true,
        ),
        CalendarEventModel(
          id: '2',
          userId: 'user1',
          title: 'Йога',
          description: 'Групповое занятие',
          eventDate: DateTime(now.year, now.month, now.day + 2, 18, 0),
          startTime: '18:00:00',
          endTime: '19:30:00',
          notificationEnabled: true,
        ),
        CalendarEventModel(
          id: '3',
          userId: 'user1',
          title: 'День рождения',
          description: 'Праздник с друзьями',
          eventDate: DateTime(now.year, now.month, now.day + 5, 19, 0),
          startTime: '19:00:00',
          endTime: '23:00:00',
          notificationEnabled: true,
        ),
      ];

      for (final event in testEvents) {
        final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
        _events.putIfAbsent(day, () => []).add(event);
      }

      emit(CalendarLoaded(
        events: Map.from(_events),
        selectedDay: now,
        focusedDay: now,
      ));
    } catch (e) {
      emit(CalendarError('Ошибка загрузки календаря: $e'));
    }
  }

  Future<void> _onAddEvent(
    AddEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final day = DateTime(
        event.event.eventDate.year,
        event.event.eventDate.month,
        event.event.eventDate.day,
      );
      _events.putIfAbsent(day, () => []).add(event.event);
      
      if (state is CalendarLoaded) {
        final loadedState = state as CalendarLoaded;
        emit(CalendarLoaded(
          events: Map.from(_events),
          selectedDay: loadedState.selectedDay,
          focusedDay: loadedState.focusedDay,
        ));
      }
      // TODO: Сохранение в API
    } catch (e) {
      emit(CalendarError('Ошибка добавления события: $e'));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final day = DateTime(
        event.event.eventDate.year,
        event.event.eventDate.month,
        event.event.eventDate.day,
      );
      
      // Удаляем старое событие
      _events[day]?.removeWhere((e) => e.id == event.event.id);
      // Добавляем обновленное
      _events.putIfAbsent(day, () => []).add(event.event);
      
      if (state is CalendarLoaded) {
        final loadedState = state as CalendarLoaded;
        emit(CalendarLoaded(
          events: Map.from(_events),
          selectedDay: loadedState.selectedDay,
          focusedDay: loadedState.focusedDay,
        ));
      }
      // TODO: Сохранение в API
    } catch (e) {
      emit(CalendarError('Ошибка обновления события: $e'));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      // Удаляем событие из всех дней
      for (final day in _events.keys) {
        _events[day]?.removeWhere((e) => e.id == event.eventId);
      }

      // Очищаем пустые списки
      _events.removeWhere((day, events) => events.isEmpty);

      // Всегда эмитим новое состояние
      final currentState = state;
      if (currentState is CalendarLoaded) {
        emit(CalendarLoaded(
          events: Map.from(_events),
          selectedDay: currentState.selectedDay,
          focusedDay: currentState.focusedDay,
        ));
      } else {
        // Если состояние не загружено, загружаем календарь заново
        await _onLoadCalendar(LoadCalendar(month: DateTime.now()), emit);
      }
      // TODO: Удаление из API
    } catch (e) {
      emit(CalendarError('Ошибка удаления события: $e'));
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
      ));
    }
  }
}
