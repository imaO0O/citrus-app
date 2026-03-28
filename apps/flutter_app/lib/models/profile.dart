class Profile {
  final String id;
  final String? name;
  final String email;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.name,
    required this.email,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };
}