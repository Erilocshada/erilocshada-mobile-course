import 'package:dio/dio.dart';

import '../models/comment.dart';

class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil daftar komentar untuk post tertentu.
  ///
  /// Endpoint yang dipanggil: GET /comments?postId={id}
  /// Hasil response adalah list of JSON, lalu di-mapping ke model Comment.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    final data = response.data ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
