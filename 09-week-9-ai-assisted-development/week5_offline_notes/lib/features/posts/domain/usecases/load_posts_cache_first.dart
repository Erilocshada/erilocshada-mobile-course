import '../../../../core/failures.dart';
import '../entities/post.dart';
import '../repositories/post_cache_repository.dart';
import '../repositories/post_repository.dart';

/// Use case: cache-first.
///
/// Kebijakan lama dari `loadPostsCacheFirst()` di minggu 5: tampilkan apa yang
/// sudah ada di cache seketika, lalu diam-diam segarkan dari jaringan. Kalau
/// jaringan gagal, cache tetap dipakai — bukan error.
class LoadPostsCacheFirst {
  const LoadPostsCacheFirst(this._remote, this._cache);

  final PostRepository _remote;
  final PostCacheRepository _cache;

  Future<({List<Post>? posts, Failure? failure})> call() async {
    final cached = await _cache.readCached();
    if (cached.failure != null) {
      return (posts: null, failure: cached.failure);
    }

    // Fire-and-forget: pemanggil tidak menunggu jaringan.
    refreshInBackground();

    return (posts: cached.posts ?? const [], failure: null);
  }

  Future<void> refreshInBackground() async {
    final fetched = await _remote.fetchPosts();
    if (fetched.failure != null || fetched.posts == null) return;
    await _cache.writeCached(fetched.posts!);
  }
}
