class MemoryPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime? photoDate;
  final bool isFavorite;
  final DateTime createdAt;

  MemoryPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    this.photoDate,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) => MemoryPhoto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        imageUrl: json['image_url'] as String,
        caption: json['caption'] as String?,
        photoDate: json['photo_date'] != null ? DateTime.parse(json['photo_date'] as String) : null,
        isFavorite: json['is_favorite'] == true,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'image_url': imageUrl,
        'caption': caption,
        'photo_date': photoDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}