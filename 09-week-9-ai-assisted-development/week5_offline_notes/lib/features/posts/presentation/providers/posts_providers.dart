import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/post_cache_repository_impl.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_cache_repository.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/load_posts_cache_first.dart';

/// Wiring DI fitur posts. Belum ada halaman yang memakainya di minggu 5;
/// provider ini tersedia untuk jobsheet berikutnya.

final postsDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
});

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepositoryImpl(ref.watch(postsDioProvider)),
);

final postCacheRepositoryProvider = Provider<PostCacheRepository>(
  (ref) => PostCacheRepositoryImpl(),
);

final loadPostsCacheFirstProvider = Provider<LoadPostsCacheFirst>(
  (ref) => LoadPostsCacheFirst(
    ref.watch(postRepositoryProvider),
    ref.watch(postCacheRepositoryProvider),
  ),
);

final cachedPostsProvider = FutureProvider<List<Post>>((ref) async {
  final result = await ref.watch(loadPostsCacheFirstProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.posts ?? const [];
});
