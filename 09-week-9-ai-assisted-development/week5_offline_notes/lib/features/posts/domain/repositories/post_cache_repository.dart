import '../../../../core/failures.dart';
import '../entities/post.dart';

/// Kontrak cache lokal untuk post.
///
/// Dulu cache-first diorkestrasi oleh fungsi top-level di `lib/data/sync.dart`
/// yang membuka koneksi SQLite sendiri. Sekarang penyimpanan cache adalah
/// repository tersendiri, sehingga policy-nya bisa diuji dengan dua fake.
abstract class PostCacheRepository {
  Future<({List<Post>? posts, Failure? failure})> readCached();

  Future<({Failure? failure})> writeCached(List<Post> posts);
}
