import '../../domain/entities/post.dart';

/// Bentuk JSON API + bentuk baris `cached_posts.payload`.
class PostModel extends Post {
  const PostModel({
    required super.userId,
    required super.id,
    required super.title,
    required super.body,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    userId: (json['userId'] as num?)?.toInt() ?? 0,
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  factory PostModel.fromEntity(Post post) => PostModel(
    userId: post.userId,
    id: post.id,
    title: post.title,
    body: post.body,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'id': id,
    'title': title,
    'body': body,
  };
}
