import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'models/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repo.markAllSynced();

  return dirtyCount;
}

// Cache first
Future<List<Post>> loadPostsCacheFirst(PostRepository repo) async {
  final cached = await readCachedPosts();

  refreshPostsInBackground(repo);

  return cached;
}

// Membaca cache dari SQLite
Future<List<Post>> readCachedPosts() async {
  final db = await openNotesDb();

  final rows = await db.query(
    'cached_posts',
    orderBy: 'id ASC',
  );
  return rows.map((row) {
    final json = jsonDecode(
      row['payload'] as String,
    );

    return Post.fromJson(
      json as Map<String, dynamic>,
    );
  }).toList();
}

// Menyimpan data API ke SQLite
Future<void> saveCachedPosts(
    List<Post> posts,
    ) async {
  final db = await openNotesDb();

  final batch = db.batch();

  for (final post in posts) {
    batch.insert(
      'cached_posts',
      {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  await batch.commit(noResult: true);
}

// Refresh API di background
Future<void> refreshPostsInBackground(PostRepository repo) async {
  try {
    final posts = await repo.fetchPosts();

    await saveCachedPosts(posts);
  } catch (_) {
    // Jika internet gagal, cache lokal tetap digunakan.
  }
}
