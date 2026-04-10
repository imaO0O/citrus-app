import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/sleep_repository.dart';
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
  final MoodRepository _moodRepository = MoodRepository(userId: 'unknown', token: null);
  SleepRepository? _sleepRepository;

  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<MoodSelected>(_onMoodSelected);
    on<MoodLogRefresh>(_onRefresh);
  }

  void updateUserId(String userId, {String? token}) {
    _moodRepository.setUserId(userId, token: token);
    add(DashboardLoad());
  }

  void setSleepRepository(SleepRepository repository) {
    _sleepRepository = repository;
  }

  Future<String> _getSleepHours() async {
    if (_sleepRepository == null || _sleepRepository!.userId == 'unknown') {
      return '—';
    }

    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day);

      final records = await _sleepRepository!.getSleepRecords(
        startDate: yesterday,
        endDate: tomorrow,
      );

      // Находим запись за вчера
      for (final record in records) {
        final rd = DateTime(record.sleepDate.year, record.sleepDate.month, record.sleepDate.day);
        if (rd.isAtSameMomentAs(yesterday) && record.bedTime != null && record.wakeTime != null) {
          final bedParts = record.bedTime!.split(':');
          final wakeParts = record.wakeTime!.split(':');
          final bedHour = int.tryParse(bedParts[0]) ?? 0;
          final bedMin = int.tryParse(bedParts[1]) ?? 0;
          final wakeHour = int.tryParse(wakeParts[0]) ?? 0;
          final wakeMin = int.tryParse(wakeParts[1]) ?? 0;

          double hours = (wakeHour + wakeMin / 60) - (bedHour + bedMin / 60);
          if (hours < 0) hours += 24;

          final h = hours.floor();
          final m = ((hours - h) * 60).round();
          return '${h}ч ${m}м';
        }
      }
    } catch (e) {
      // ignore
    }

    return '—';
  }

  Future<void> _onLoad(DashboardLoad event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    try {
      final streak = await _moodRepository.getStreak();
      final goodDays = await _moodRepository.getGoodDaysPercentage();
      final todayRecords = await _moodRepository.getTodayRecords();
      final lastRecord = await _moodRepository.getLastRecord();
      final avgMood = await _moodRepository.getAverageMood();
      final sleepHours = await _getSleepHours();

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
        sleepHours: sleepHours,
        todayLog: todayLog,
        lastEntry: lastRecord,
        averageMood: avgMood,
      ));
    } catch (e) {
      emit(DashboardLoaded());
    }
  }

  Future<void> _onMoodSelected(
    MoodSelected event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;
    emit(current.copyWith(selectedMoodId: event.moodId));

    try {
      await _moodRepository.createRecord(event.moodId, timestamp: event.timestamp);
      await Future.delayed(const Duration(milliseconds: 1500));

      final streak = await _moodRepository.getStreak();
      final goodDays = await _moodRepository.getGoodDaysPercentage();
      final todayRecords = await _moodRepository.getTodayRecords();
      final lastRecord = await _moodRepository.getLastRecord();
      final sleepHours = await _getSleepHours();

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
        sleepHours: sleepHours,
      ));
    } catch (e) {
      debugPrint('DashboardBloc: ошибка сохранения настроения: $e');
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
      final streak = await _moodRepository.getStreak();
      final goodDays = await _moodRepository.getGoodDaysPercentage();
      final todayRecords = await _moodRepository.getTodayRecords();
      final lastRecord = await _moodRepository.getLastRecord();
      final sleepHours = await _getSleepHours();

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
        sleepHours: sleepHours,
      ));
    } catch (e) {
      // ignore
    }
  }
}
