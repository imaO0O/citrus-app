class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? startTime;   // формат "HH:mm:ss"
  final String? endTime;     // формат "HH:mm:ss"
  final bool notificationEnabled;

  CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.notificationEnabled,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        description: json['description'],
        eventDate: DateTime.parse(json['event_date']),
        startTime: json['start_time'],
        endTime: json['end_time'],
        notificationEnabled: json['notification_enabled'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String(),
        'start_time': startTime,
        'end_time': endTime,
        'notification_enabled': notificationEnabled,
      };
}