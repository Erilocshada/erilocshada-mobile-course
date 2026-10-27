import '../../domain/entities/announcement.dart';

/// Model = representasi JSON dari server. Mapping HANYA di sini.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.publishedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(
            json['published_at'] as String? ??
                json['createdAt'] as String? ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'published_at': publishedAt.toIso8601String(),
  };

  Announcement toEntity() =>
      Announcement(id: id, title: title, body: body, publishedAt: publishedAt);
}
