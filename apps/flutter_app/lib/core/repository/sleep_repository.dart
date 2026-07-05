import '../../../models/sleep_record.dart';
import '../../../core/api/sleep_api_service.dart';
import '../services/offline_queue_service.dart';

/// Репозиторий для работы с трекером сна
class SleepRepository {
  SleepApiService _apiService;
  String _userId;

  SleepRepository({
    required String userId,
    String? token,
    SleepApiService? apiService,
  })  : _userId = userId,
        _apiService = apiService ?? SleepApiService(token: token);

  /// Обновить userId и токен
  void setUserId(String userId, {String? token}) {
    _userId = userId;
    if (token != null) {
      _apiService = SleepApiService(token: token);
    }
  }

  String get userId => _userId;

  /// Получить записи сна
  Future<List<SleepRecord>> getSleepRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _apiService.getSleepRecords(
      userId: _userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Создать запись сна
  Future<SleepRecord> createSleepRecord(SleepRecord record) async {
    try {
      return await _apiService.createSleepRecord(record);
    } catch (e) {
      // Нет сети — кладём запись в офлайн-очередь, возвращаем её же оптимистично.
      if (OfflineQueueService.isNetworkError(e)) {
        await OfflineQueueService.instance.enqueue('sleep', record.toJson());
        return record;
      }
      rethrow;
    }
  }

  /// Повторная отправка из офлайн-очереди.
  Future<void> replayCreate(Map<String, dynamic> d) async {
    await _apiService.createSleepRecord(SleepRecord.fromJson(d));
  }

  /// Обновить запись сна
  Future<SleepRecord> updateSleepRecord(SleepRecord record) async {
    return await _apiService.updateSleepRecord(record);
  }

  /// Удалить запись сна
  Future<void> deleteSleepRecord(String recordId) async {
    await _apiService.deleteSleepRecord(recordId);
  }
}
