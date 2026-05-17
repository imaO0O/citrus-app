class Article {
  final String id;
  final String? userId; // null для системных
  final String title;
  final String content;
  final String category;
  final bool isCustom;
  final DateTime createdAt;
  final String source; // 'app', 'wikipedia'
  final List<String>? tags;

  Article({
    required this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.isCustom,
    required this.createdAt,
    this.source = 'app',
    this.tags,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        content: json['content'],
        category: json['category'],
        isCustom: json['is_custom'],
        createdAt: DateTime.parse(json['created_at']),
        source: json['source'] ?? 'app',
        tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'category': category,
        'is_custom': isCustom,
        'created_at': createdAt.toIso8601String(),
        'source': source,
        'tags': tags,
      };
}
