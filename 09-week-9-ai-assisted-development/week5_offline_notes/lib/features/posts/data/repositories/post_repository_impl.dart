import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

/// Implementasi HTTP dari [PostRepository].
class PostRepositoryImpl implements PostRepository {
  const PostRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<({List<Post>? posts, Failure? failure})> fetchPosts() async {
    try {
      final response = await _dio.get<List>('/posts');
      final data = response.data ?? const <Never>[];
      return (
        posts: data
            .whereType<Map<String, dynamic>>()
            .map(PostModel.fromJson)
            .toList(),
        failure: null,
      );
    } on DioException catch (e) {
      return (
        posts: null,
        failure: NetworkFailure('Gagal mengambil post: ${e.message ?? e.type}'),
      );
    } catch (e) {
      return (posts: null, failure: LocalFailure('Data post tidak valid: $e'));
    }
  }
}
