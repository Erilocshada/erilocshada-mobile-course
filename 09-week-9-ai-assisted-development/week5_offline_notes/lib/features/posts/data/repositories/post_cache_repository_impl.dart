import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/db.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_cache_repository.dart';
import '../models/post_model.dart';

/// Cache post di tabel `cached_posts`.
///
/// Menggantikan `readCachedPosts`/`saveCachedPosts` top-level di minggu 5 yang
/// memanggil `openNotesDb()` sendiri. Koneksi masuk lewat injeksi, dan
/// [sharedNotesDb] menjamin satu koneksi bersama untuk seluruh aplikasi.
class PostCacheRepositoryImpl implements PostCacheRepository {
  PostCacheRepositoryImpl({Future<Database> Function()? openDb})
    : _openDb = openDb ?? sharedNotesDb;

  final Future<Database> Function() _openDb;

  static const _table = 'cached_posts';

  @override
  Future<({List<Post>? posts, Failure? failure})> readCached() async {
    try {
      final db = await _openDb();
      final rows = await db.query(_table, orderBy: 'id ASC');
      return (
        posts: rows.map((row) {
          return PostModel.fromJson(
            jsonDecode(row['payload'] as String) as Map<String, dynamic>,
          );
        }).toList(),
        failure: null,
      );
    } catch (e) {
      return (
        posts: null,
        failure: LocalFailure('Gagal membaca cache post: $e'),
      );
    }
  }

  @override
  Future<({Failure? failure})> writeCached(List<Post> posts) async {
    try {
      final db = await _openDb();
      final batch = db.batch();
      for (final post in posts) {
        batch.insert(_table, {
          'id': post.id,
          'payload': jsonEncode(PostModel.fromEntity(post).toJson()),
          'cached_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      return (failure: null);
    } catch (e) {
      return (failure: LocalFailure('Gagal menyimpan cache post: $e'));
    }
  }
}
