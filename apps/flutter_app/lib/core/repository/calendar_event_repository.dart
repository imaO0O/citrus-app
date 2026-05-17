import '../../../models/calendar_event.dart';
import '../api/calendar_event_api_service.dart';

/// Репозиторий для работы с событиями календаря
class CalendarEventRepository {
  CalendarEventApiService _apiService;
  String _userId;
  String? _token;

  // Временный кэш только для текущего пользователя (сбрасывается при смене userId)
  Map<DateTime, List<CalendarEventModel>> _cache = {};

  CalendarEventRepository({
    required String userId,
    String? token,
    CalendarEventApiService? apiService,
  })  : _userId = userId,
        _token = token,
        _apiService = apiService ?? CalendarEventApiService(token: token);

  /// Обновить userId и токен (при входе нового пользователя)
  void setUserId(String userId, {String? token}) {
    print('CalendarEventRepository: смена userId с $_userId на $userId');
    print('  - получен token: ${token != null ? "length=${token.length}" : "null"}');
    _userId = userId;
    if (token != null) {
      _token = token;
      print('  - _token обновлён (length=${_token!.length})');
      // Обновляем токен в API сервисе
      _apiService = CalendarEventApiService(token: token);
      print('  - _apiService пересоздан с новым токеном');
    } else {
      print('  - token is null, _apiService не обновляется с токеном');
    }
    // Очищаем кэш при смене пользователя — будем загружать из БД
    _cache = {};
  }

  String get userId => _userId;
  String? get token => _token;

  /// Получить события за месяц
  Future<List<CalendarEventModel>> getEventsForMonth(DateTime month) async {
    try {
      final events = await _apiService.getEventsForMonth(
        userId: userId,
        month: month,
      );

      // Кэшируем события
      _cache = {};
      for (final event in events) {
        final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
        _cache.putIfAbsent(day, () => []).add(event);
      }

      return events;
    } catch (e) {
      print('Ошибка загрузки событий: $e');
      // Возвращаем кэш при ошибке
      return _getAllCachedEvents();
    }
  }

  /// Получить события за день
  List<CalendarEventModel> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _cache[normalizedDay] ?? [];
  }

  /// Создать событие
  Future<CalendarEventModel> createEvent(CalendarEventModel event) async {
    try {
      final createdEvent = await _apiService.createEvent(event);

      // Обновляем кэш
      final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      _cache.putIfAbsent(day, () => []).add(createdEvent);

      return createdEvent;
    } catch (e) {
      // Сохраняем локально
      final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      _cache.putIfAbsent(day, () => []).add(event);
      return event;
    }
  }

  /// Обновить событие
  Future<CalendarEventModel> updateEvent(CalendarEventModel event) async {
    try {
      final updatedEvent = await _apiService.updateEvent(event);

      // Обновляем кэш
      await _removeFromCache(event.id);
      final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      _cache.putIfAbsent(day, () => []).add(updatedEvent);

      return updatedEvent;
    } catch (e) {
      // Обновляем локально
      await _removeFromCache(event.id);
      final day = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
      _cache.putIfAbsent(day, () => []).add(event);
      return event;
    }
  }

  /// Удалить событие
  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiService.deleteEvent(eventId);
    } catch (e) {
      // Игнорируем ошибку API, удаляем только локально
    } finally {
      await _removeFromCache(eventId);
    }
  }

  /// Удалить событие из кэша
  Future<void> _removeFromCache(String eventId) async {
    for (final day in _cache.keys) {
      _cache[day]?.removeWhere((e) => e.id == eventId);
    }
    _cache.removeWhere((day, events) => events.isEmpty);
  }

  /// Получить все кэшированные события
  List<CalendarEventModel> _getAllCachedEvents() {
    final allEvents = <CalendarEventModel>[];
    for (final events in _cache.values) {
      allEvents.addAll(events);
    }
    return allEvents;
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
  }

  /// Получить все события из кэша
  Map<DateTime, List<CalendarEventModel>> get allCachedEvents => Map.from(_cache);
}
