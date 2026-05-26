class SleepRecord {
  final String id;
  final String userId;
  final DateTime sleepDate;
  final String? bedTime;
  final String? wakeTime;
  final int? quality;

  SleepRecord({
    required this.id,
    required this.userId,
    required this.sleepDate,
    this.bedTime,
    this.wakeTime,
    this.quality,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    // Преобразуем bed_time и wake_time из байт в строку если нужно
    String? bedTime;
    if (json['bed_time'] != null) {
      if (json['bed_time'] is String) {
        final bedTimeStr = json['bed_time'] as String;
        if (bedTimeStr.isNotEmpty) {
          bedTime = bedTimeStr;
        }
      } else if (json['bed_time'] is List<int>) {
        final bedTimeBytes = json['bed_time'] as List<int>;
        final bedTimeStr = String.fromCharCodes(bedTimeBytes);
        if (bedTimeStr.isNotEmpty) {
          bedTime = bedTimeStr;
        }
      }
    }
    
    String? wakeTime;
    if (json['wake_time'] != null) {
      if (json['wake_time'] is String) {
        final wakeTimeStr = json['wake_time'] as String;
        if (wakeTimeStr.isNotEmpty) {
          wakeTime = wakeTimeStr;
        }
      } else if (json['wake_time'] is List<int>) {
        final wakeTimeBytes = json['wake_time'] as List<int>;
        final wakeTimeStr = String.fromCharCodes(wakeTimeBytes);
        if (wakeTimeStr.isNotEmpty) {
          wakeTime = wakeTimeStr;
        }
      }
    }
    
    return SleepRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sleepDate: DateTime.parse(json['sleep_date'] as String),
      bedTime: bedTime,
      wakeTime: wakeTime,
      quality: json['quality'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sleep_date': sleepDate.toIso8601String().split('T').first,
      'bed_time': bedTime,
      'wake_time': wakeTime,
      'quality': quality,
    };
  }
}
