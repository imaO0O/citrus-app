class Article {
  final String id;
  final String? userId; // null для системных
  final String title;
  final String content;
  final String category;
  final bool isCustom;
  final DateTime createdAt;

  Article({
    required this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.isCustom,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        content: json['content'],
        category: json['category'],
        isCustom: json['is_custom'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
        'is_custom': isCustom,
        'created_at': createdAt.toIso8601String(),
      };
}