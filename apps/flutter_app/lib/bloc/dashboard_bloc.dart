import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/repository/mood_repository.dart';
import '../screens/models/mood.dart';

// ─── Events ───────────────────────────────────────────────
abstract class DashboardEvent {}

class DashboardLoad extends DashboardEvent {}

class MoodSelected extends DashboardEvent {
  final int moodId;
  final DateTime timestamp;

  MoodSelected({required this.moodId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class MoodLogRefresh extends DashboardEvent {}

// ─── States ────────────────────────────────────────────────
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int streakDays;
  final String goodDaysPercent;
  final String sleepHours;
  final List<MoodLogEntry> todayLog;
  final int? selectedMoodId;
  final MoodLogEntry? lastEntry;
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
    MoodLogEntry? lastEntry,
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

// ─── BLoC ──────────────────────────────────────────────────
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<MoodSelected>(_onMoodSelected);
    on<MoodLogRefresh>(_onRefresh);
  }

  Future<void> _onLoad(DashboardLoad event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    final streak = await MoodRepository.getStreak();
    final goodDays = await MoodRepository.getGoodDaysPercentage();
    final todayLog = await MoodRepository.getTodayEntries();
    final lastEntry = await MoodRepository.getLastEntry();
    final avgMood = await MoodRepository.getAverageMood();

    emit(DashboardLoaded(
      streakDays: streak,
      goodDaysPercent: '${goodDays.round()}%',
      sleepHours: '7.2ч',
      todayLog: todayLog.take(4).toList(),
      lastEntry: lastEntry,
      averageMood: avgMood,
    ));
  }

  Future<void> _onMoodSelected(
    MoodSelected event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;

    // Временно показываем selected
    emit(current.copyWith(selectedMoodId: event.moodId));

    // Сохраняем
    final entry = MoodLogEntry(
      timestamp: event.timestamp,
      moodId: event.moodId,
    );
    await MoodRepository.addEntry(entry);

    // Обновляем данные через 1.5 сек
    await Future.delayed(const Duration(milliseconds: 1500));

    final streak = await MoodRepository.getStreak();
    final goodDays = await MoodRepository.getGoodDaysPercentage();
    final todayLog = await MoodRepository.getTodayEntries();
    final lastEntry = await MoodRepository.getLastEntry();

    emit(current.copyWith(
      streakDays: streak,
      goodDaysPercent: '${goodDays.round()}%',
      todayLog: todayLog.take(4).toList(),
      lastEntry: lastEntry,
      selectedMoodId: null,
    ));
  }

  Future<void> _onRefresh(
    MoodLogRefresh event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;
    final streak = await MoodRepository.getStreak();
    final goodDays = await MoodRepository.getGoodDaysPercentage();
    final todayLog = await MoodRepository.getTodayEntries();
    final lastEntry = await MoodRepository.getLastEntry();

    emit(current.copyWith(
      streakDays: streak,
      goodDaysPercent: '${goodDays.round()}%',
      todayLog: todayLog.take(4).toList(),
      lastEntry: lastEntry,
    ));
  }
}
