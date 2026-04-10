import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/sleep_record.dart';
import '../../../core/repository/sleep_repository.dart';

// События
abstract class SleepEvent {
  const SleepEvent();
}

class LoadSleepRecords extends SleepEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadSleepRecords({required this.startDate, required this.endDate});
}

class AddSleepRecord extends SleepEvent {
  final SleepRecord record;

  const AddSleepRecord(this.record);
}

class UpdateSleepRecord extends SleepEvent {
  final SleepRecord record;

  const UpdateSleepRecord(this.record);
}

class DeleteSleepRecord extends SleepEvent {
  final String recordId;

  const DeleteSleepRecord(this.recordId);
}

// Состояния
abstract class SleepState {
  const SleepState();
}

class SleepInitial extends SleepState {
  const SleepInitial();
}

class SleepLoading extends SleepState {
  const SleepLoading();
}

class SleepLoaded extends SleepState {
  final List<SleepRecord> records;

  const SleepLoaded(this.records);

  /// Получить среднее качество сна
  double? get averageQuality {
    if (records.isEmpty) return null;
    final qualityRecords = records.where((r) => r.quality != null).toList();
    if (qualityRecords.isEmpty) return null;
    final sum = qualityRecords.fold<int>(0, (sum, r) => sum + r.quality!);
    return sum / qualityRecords.length;
  }

  /// Получить среднее время сна (в часах)
  double? get averageSleepDuration {
    if (records.isEmpty) return null;
    final durations = records.where((r) => 
      r.bedTime != null && r.bedTime!.isNotEmpty && 
      r.wakeTime != null && r.wakeTime!.isNotEmpty
    ).toList();
    if (durations.isEmpty) return null;

    double totalHours = 0;
    int validCount = 0;
    
    for (final record in durations) {
      final bed = _parseTime(record.bedTime!);
      final wake = _parseTime(record.wakeTime!);
      if (bed == null || wake == null) continue;
      
      double hours = wake - bed;
      if (hours < 0) hours += 24; // Если ночь перешла через полночь
      totalHours += hours;
      validCount++;
    }
    
    if (validCount == 0 || totalHours == 0) return null;
    return totalHours / validCount;
  }

  double? _parseTime(String timeStr) {
    if (!timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + minute / 60.0;
    } catch (e) {
      return null;
    }
  }
}

class SleepError extends SleepState {
  final String message;

  const SleepError(this.message);
}

// BLoC
class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepRepository _repository;

  SleepBloc({required SleepRepository repository})
      : _repository = repository,
        super(const SleepInitial()) {
    on<LoadSleepRecords>(_onLoadRecords);
    on<AddSleepRecord>(_onAddRecord);
    on<UpdateSleepRecord>(_onUpdateRecord);
    on<DeleteSleepRecord>(_onDeleteRecord);
  }

  /// Обновить userId и токен
  void updateUserId(String newUserId, {String? token}) {
    _repository.setUserId(newUserId, token: token);
    add(LoadSleepRecords(
      startDate: DateTime(2020, 1, 1),
      endDate: DateTime(2030, 12, 31),
    ));
  }

  Future<void> _onLoadRecords(
    LoadSleepRecords event,
    Emitter<SleepState> emit,
  ) async {
    emit(const SleepLoading());

    try {
      final records = await _repository.getSleepRecords(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(SleepLoaded(records));
    } catch (e) {
      emit(SleepError('Ошибка загрузки: $e'));
    }
  }

  Future<void> _onAddRecord(
    AddSleepRecord event,
    Emitter<SleepState> emit,
  ) async {
    try {
      final record = await _repository.createSleepRecord(event.record);
      if (state is SleepLoaded) {
        final records = List<SleepRecord>.from((state as SleepLoaded).records);
        records.add(record);
        emit(SleepLoaded(records));
      }
    } catch (e) {
      emit(SleepError('Ошибка добавления: $e'));
    }
  }

  Future<void> _onUpdateRecord(
    UpdateSleepRecord event,
    Emitter<SleepState> emit,
  ) async {
    try {
      await _repository.updateSleepRecord(event.record);
      // Перезагружаем записи из БД после обновления
      if (state is SleepLoaded) {
        add(LoadSleepRecords(
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2030, 12, 31),
        ));
      }
    } catch (e) {
      emit(SleepError('Ошибка обновления: $e'));
    }
  }

  Future<void> _onDeleteRecord(
    DeleteSleepRecord event,
    Emitter<SleepState> emit,
  ) async {
    try {
      await _repository.deleteSleepRecord(event.recordId);
      if (state is SleepLoaded) {
        final records = (state as SleepLoaded).records
            .where((r) => r.id != event.recordId)
            .toList();
        emit(SleepLoaded(records));
      }
    } catch (e) {
      emit(SleepError('Ошибка удаления: $e'));
    }
  }
}
