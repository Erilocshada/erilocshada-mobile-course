import '../../../../core/failures.dart';
import '../entities/post.dart';

/// Kontrak sumber data jauh (JSONPlaceholder lewat Dio).
abstract class PostRepository {
  Future<({List<Post>? posts, Failure? failure})> fetchPosts();
}
