class DiaryEntry {
  final String id;
  final String userId;
  final String content;
  final int? moodValue;
  final DateTime entryDate;
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.content,
    this.moodValue,
    required this.entryDate,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: json['id'],
        userId: json['user_id'],
        content: json['content'],
        moodValue: json['mood_value'],
        entryDate: DateTime.parse(json['entry_date']),
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'mood_value': moodValue,
        'entry_date': entryDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}