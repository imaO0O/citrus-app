class UserPreferences {
  final String userId;
  final Map<String, dynamic> preferences; // JSONB
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.preferences,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        userId: json['user_id'],
        preferences: json['preferences'],
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'preferences': preferences,
        'updated_at': updatedAt.toIso8601String(),
      };
}