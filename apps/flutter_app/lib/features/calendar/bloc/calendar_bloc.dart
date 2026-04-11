import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/calendar_event.dart';
import '../../../core/repository/calendar_event_repository.dart';
import '../../../core/repository/mood_repository.dart';

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

  /// Получить события месяца
  List<CalendarEventModel> getEventsForMonth(DateTime month) {
    final allEvents = events.values.expand((e) => e).toList();
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    
    return allEvents.where((event) {
      final eventDate = event.eventDate;
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      return (eventDay.isAtSameMomentAs(monthStart) || eventDay.isAfter(monthStart)) &&
             (eventDay.isAtSameMomentAs(monthEnd) || eventDay.isBefore(monthEnd));
    }).toList();
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

  CalendarBloc({
    required CalendarEventRepository repository,
    required MoodRepository moodRepository,
  })  : _repository = repository,
        _moodRepository = moodRepository,
        super(const CalendarInitial()) {
    on<LoadCalendar>(_onLoadCalendar);
    on<AddEvent>(_onAddEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<SelectDay>(_onSelectDay);
  }

  /// Обновить userId и перезагрузить календарь
  void updateUserId(String newUserId, {String? token}) {
    print('CalendarBloc: обновление userId на $newUserId');
    print('  - получен token: ${token != null ? "length=${token.length}" : "null"}');
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
    print('CalendarBloc: загрузка календаря для userId=${_repository.userId}, месяц=${event.month}');
    emit(const CalendarLoading());

    try {
      final events = await _repository.getEventsForMonth(event.month);
      print('CalendarBloc: загружено ${events.length} событий');

      // Группируем события по дням
      final Map<DateTime, List<CalendarEventModel>> eventsByDay = {};
      for (final event in events) {
        final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
        eventsByDay.putIfAbsent(day, () => []).add(event);
      }
      print('CalendarBloc: сгруппировано по ${eventsByDay.length} дням');

      // Загружаем средние настроения по дням для всего месяца
      final monthStart = DateTime(event.month.year, event.month.month, 1);
      final monthEnd = DateTime(event.month.year, event.month.month + 1, 0);
      final moodAverages = await _moodRepository.getAverageMoodByDay(
        startDate: monthStart,
        endDate: monthEnd,
      );
      print('CalendarBloc: загружены данные настроения для ${moodAverages.length} дней');

      final now = DateTime.now();
      emit(CalendarLoaded(
        events: eventsByDay,
        selectedDay: now,
        focusedDay: now,
        moodAverages: moodAverages,
      ));
    } catch (e) {
      print('CalendarBloc: ошибка загрузки: $e');
      emit(CalendarError('Ошибка загрузки календаря: $e'));
    }
  }

  Future<void> _onAddEvent(
    AddEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final createdEvent = await _repository.createEvent(event.event);

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

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _repository.updateEvent(event.event);
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
    try {
      await _repository.deleteEvent(event.eventId);

      if (state is CalendarLoaded) {
        final loadedState = state as CalendarLoaded;
        final updatedEvents = Map<DateTime, List<CalendarEventModel>>.from(loadedState.events);
        
        // Удаляем событие из всех дней
        for (final day in updatedEvents.keys) {
          updatedEvents[day]?.removeWhere((e) => e.id == event.eventId);
        }
        // Очищаем пустые списки
        updatedEvents.removeWhere((day, events) => events.isEmpty);

        emit(CalendarLoaded(
          events: updatedEvents,
          selectedDay: loadedState.selectedDay,
          focusedDay: loadedState.focusedDay,
          moodAverages: loadedState.moodAverages,
        ));
      }
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
        moodAverages: loadedState.moodAverages,
      ));
    }
  }
}
