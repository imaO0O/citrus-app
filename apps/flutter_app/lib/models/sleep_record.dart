class SleepRecord {
  final String id;
  final String userId;
  final DateTime sleepDate;
  final String bedTime;   // формат "HH:mm:ss"
  final String wakeTime;  // формат "HH:mm:ss"
  final int quality;      // 1-5

  SleepRecord({
    required this.id,
    required this.userId,
    required this.sleepDate,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) => SleepRecord(
        id: json['id'],
        userId: json['user_id'],
        sleepDate: DateTime.parse(json['sleep_date']),
        bedTime: json['bed_time'],
        wakeTime: json['wake_time'],
        quality: json['quality'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'sleep_date': sleepDate.toIso8601String(),
        'bed_time': bedTime,
        'wake_time': wakeTime,
        'quality': quality,
      };
}