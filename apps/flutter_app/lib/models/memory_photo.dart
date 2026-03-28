class MemoryPhoto {
  final String id;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime? photoDate;
  final DateTime createdAt;

  MemoryPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.caption,
    this.photoDate,
    required this.createdAt,
  });

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) => MemoryPhoto(
        id: json['id'],
        userId: json['user_id'],
        imageUrl: json['image_url'],
        caption: json['caption'],
        photoDate: json['photo_date'] != null ? DateTime.parse(json['photo_date']) : null,
        createdAt: DateTime.parse(json['created_at']),
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