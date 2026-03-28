class MoodEntry {
  final String id;
  final String userId;
  final int moodValue;
  final DateTime recordedAt;
  final DateTime date;
  final String timeOfDay;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.moodValue,
    required this.recordedAt,
    required this.date,
    required this.timeOfDay,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'],
        userId: json['user_id'],
        moodValue: json['mood_value'],
        recordedAt: DateTime.parse(json['recorded_at']),
        date: DateTime.parse(json['date']),
        timeOfDay: json['time_of_day'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mood_value': moodValue,
        'recorded_at': recordedAt.toIso8601String(),
        'date': date.toIso8601String(),
        'time_of_day': timeOfDay,
      };
}