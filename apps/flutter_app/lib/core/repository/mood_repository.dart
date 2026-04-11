import 'package:intl/intl.dart';
import '../../../core/api/mood_api_service.dart';

class MoodRecord {
  final String id;
  final String userId;
  final int moodId;
  final DateTime moodDate;
  final String? note;

  MoodRecord({
    required this.id,
    required this.userId,
    required this.moodId,
    required this.moodDate,
    this.note,
  });

  factory MoodRecord.fromJson(Map<String, dynamic> json) {
    // Поддерживаем оба варианта имени поля
    final moodId = json['mood_id'] ?? json['mood_value'];
    final moodDateStr = json['mood_date'] as String?;
    DateTime moodDate;
    if (moodDateStr != null) {
      try {
        moodDate = DateTime.parse(moodDateStr);
      } catch (_) {
        moodDate = DateTime.now();
      }
    } else {
      moodDate = DateTime.now();
    }

    return MoodRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      moodId: moodId as int,
      moodDate: moodDate,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood_id': moodId,
      'mood_date': moodDate.toIso8601String(),
      'note': note,
    };
  }
}

class MoodRepository {
  MoodApiService _apiService;
  String _userId;
  String? _token;

  MoodRepository({
    required String userId,
    String? token,
    MoodApiService? apiService,
  })  : _userId = userId,
        _token = token,
        _apiService = apiService ?? MoodApiService(token: token);

  void setUserId(String userId, {String? token}) {
    _userId = userId;
    if (token != null && token.isNotEmpty) {
      _token = token;
      _apiService = MoodApiService(token: token);
    }
  }

  String get userId => _userId;

  Future<List<MoodRecord>> getRecords({DateTime? startDate, DateTime? endDate}) async {
    final data = await _apiService.getMoodRecords(
      startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null,
      endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
    );
    return data.map((e) => MoodRecord.fromJson(e)).toList();
  }

  Future<MoodRecord> createRecord(int moodId, {DateTime? timestamp, String? note}) async {
    final data = await _apiService.createMoodRecord(
      moodId: moodId,
      moodDate: timestamp?.toIso8601String(),
      note: note,
    );
    return MoodRecord.fromJson(data);
  }

  Future<MoodRecord> updateRecord({required String id, required int moodId, String? note}) async {
    final data = await _apiService.updateMoodRecord(id: id, moodId: moodId, note: note);
    return MoodRecord.fromJson(data);
  }

  Future<void> deleteRecord(String id) async {
    await _apiService.deleteMoodRecord(id);
  }

  Future<int> getStreak() async {
    final now = DateTime.now();
    final records = await getRecords(startDate: now.subtract(const Duration(days: 365)));

    int streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final dayRecords = records.where((r) {
        final rd = DateTime(r.moodDate.year, r.moodDate.month, r.moodDate.day);
        return rd.isAtSameMomentAs(checkDate);
      });
      if (dayRecords.isEmpty) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<double> getGoodDaysPercentage() async {
    final now = DateTime.now();
    final records = await getRecords(startDate: now.subtract(const Duration(days: 7)));

    if (records.isEmpty) return 0;

    final uniqueDays = <String>{};
    final goodDays = <String>{};

    for (final record in records) {
      final dayKey = '${record.moodDate.year}-${record.moodDate.month}-${record.moodDate.day}';
      uniqueDays.add(dayKey);
      if (record.moodId <= 1) {
        goodDays.add(dayKey);
      }
    }

    if (uniqueDays.isEmpty) return 0;
    return (goodDays.length / uniqueDays.length) * 100;
  }

  Future<double> getAverageMood() async {
    final now = DateTime.now();
    final records = await getRecords(startDate: now.subtract(const Duration(days: 7)));
    if (records.isEmpty) return 0;
    return records.map((e) => e.moodId).reduce((a, b) => a + b) / records.length;
  }

  Future<List<MoodRecord>> getTodayRecords() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Начало сегодняшнего дня (00:00:00)
    final tomorrow = today.add(const Duration(days: 1));
    final records = await getRecords(startDate: today, endDate: tomorrow);
    return records..sort((a, b) => a.moodDate.compareTo(b.moodDate));
  }

  Future<MoodRecord?> getLastRecord() async {
    final now = DateTime.now();
    final records = await getRecords(startDate: now.subtract(const Duration(days: 30)));
    return records.isEmpty ? null : records.first;
  }
}
