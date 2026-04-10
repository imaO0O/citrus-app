import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/repository/mood_repository.dart';
import '../screens/models/mood.dart';

abstract class DashboardEvent {}

class DashboardLoad extends DashboardEvent {}

class MoodSelected extends DashboardEvent {
  final int moodId;
  final DateTime timestamp;

  MoodSelected({required this.moodId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class MoodLogRefresh extends DashboardEvent {}

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int streakDays;
  final String goodDaysPercent;
  final String sleepHours;
  final List<MoodLogEntry> todayLog;
  final int? selectedMoodId;
  final MoodRecord? lastEntry;
  final double averageMood;

  DashboardLoaded({
    this.streakDays = 0,
    this.goodDaysPercent = '0%',
    this.sleepHours = '—',
    this.todayLog = const [],
    this.selectedMoodId,
    this.lastEntry,
    this.averageMood = 0,
  });

  DashboardLoaded copyWith({
    int? streakDays,
    String? goodDaysPercent,
    String? sleepHours,
    List<MoodLogEntry>? todayLog,
    int? selectedMoodId,
    MoodRecord? lastEntry,
    double? averageMood,
  }) {
    return DashboardLoaded(
      streakDays: streakDays ?? this.streakDays,
      goodDaysPercent: goodDaysPercent ?? this.goodDaysPercent,
      sleepHours: sleepHours ?? this.sleepHours,
      todayLog: todayLog ?? this.todayLog,
      selectedMoodId: selectedMoodId,
      lastEntry: lastEntry,
      averageMood: averageMood ?? this.averageMood,
    );
  }
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<MoodSelected>(_onMoodSelected);
    on<MoodLogRefresh>(_onRefresh);
  }

  final MoodRepository _repository = MoodRepository(userId: 'unknown', token: null);

  void updateUserId(String userId, {String? token}) {
    _repository.setUserId(userId, token: token);
    add(DashboardLoad());
  }

  Future<void> _onLoad(DashboardLoad event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    try {
      final streak = await _repository.getStreak();
      final goodDays = await _repository.getGoodDaysPercentage();
      final todayRecords = await _repository.getTodayRecords();
      final lastRecord = await _repository.getLastRecord();
      final avgMood = await _repository.getAverageMood();

      // Конвертируем MoodRecord → MoodLogEntry для UI
      final todayLog = todayRecords
          .map((r) => MoodLogEntry(
                timestamp: r.moodDate,
                moodId: r.moodId,
              ))
          .take(4)
          .toList();

      emit(DashboardLoaded(
        streakDays: streak,
        goodDaysPercent: '${goodDays.round()}%',
        sleepHours: '—',
        todayLog: todayLog,
        lastEntry: lastRecord,
        averageMood: avgMood,
      ));
    } catch (e) {
      // При ошибке показываем пустое состояние
      emit(DashboardLoaded());
    }
  }

  Future<void> _onMoodSelected(
    MoodSelected event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;

    // Временно показываем selected
    emit(current.copyWith(selectedMoodId: event.moodId));

    try {
      // Сохраняем в БД
      await _repository.createRecord(event.moodId, timestamp: event.timestamp);

      // Обновляем данные через 1.5 сек
      await Future.delayed(const Duration(milliseconds: 1500));

      final streak = await _repository.getStreak();
      final goodDays = await _repository.getGoodDaysPercentage();
      final todayRecords = await _repository.getTodayRecords();
      final lastRecord = await _repository.getLastRecord();

      final todayLog = todayRecords
          .map((r) => MoodLogEntry(
                timestamp: r.moodDate,
                moodId: r.moodId,
              ))
          .take(4)
          .toList();

      emit(current.copyWith(
        streakDays: streak,
        goodDaysPercent: '${goodDays.round()}%',
        todayLog: todayLog,
        lastEntry: lastRecord,
        selectedMoodId: null,
      ));
    } catch (e) {
      // При ошибке просто убираем selected
      emit(current.copyWith(selectedMoodId: null));
    }
  }

  Future<void> _onRefresh(
    MoodLogRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;

    try {
      final streak = await _repository.getStreak();
      final goodDays = await _repository.getGoodDaysPercentage();
      final todayRecords = await _repository.getTodayRecords();
      final lastRecord = await _repository.getLastRecord();

      final todayLog = todayRecords
          .map((r) => MoodLogEntry(
                timestamp: r.moodDate,
                moodId: r.moodId,
              ))
          .take(4)
          .toList();

      emit(current.copyWith(
        streakDays: streak,
        goodDaysPercent: '${goodDays.round()}%',
        todayLog: todayLog,
        lastEntry: lastRecord,
      ));
    } catch (e) {
      // ignore
    }
  }
}
