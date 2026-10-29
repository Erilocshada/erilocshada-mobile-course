import 'package:sqflite/sqflite.dart';

import '../../../../core/db.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

/// Implementasi SQLite dari [NoteRepository].
///
/// Satu-satunya tempat yang boleh tahu bahwa catatan disimpan di tabel
/// `notes`. Exception mentah tidak pernah keluar dari sini: semuanya
/// dikonversi menjadi [Failure] agar presentation tidak perlu blok try/catch.
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({Future<Database> Function()? openDb})
    : _openDb = openDb ?? sharedNotesDb;

  final Future<Database> Function() _openDb;

  static const _table = 'notes';

  @override
  Future<({List<Note>? notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query(_table, orderBy: 'updated_at DESC');
      return (notes: rows.map(NoteModel.fromMap).toList(), failure: null);
    } catch (e) {
      return (notes: null, failure: LocalFailure('Gagal memuat catatan: $e'));
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = NoteModel(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );

    try {
      final db = await _openDb();
      final values = note.toMap()..remove('id');
      final id = await db.insert(_table, values);
      return (
        note: NoteModel(
          id: id,
          title: note.title,
          body: note.body,
          updatedAt: note.updatedAt,
          dirty: true,
        ),
        failure: null,
      );
    } catch (e) {
      return (note: null, failure: LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }

  @override
  Future<({Failure? failure})> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final changed = await db.update(
        _table,
        {
          'title': title,
          'body': body,
          'updated_at': DateTime.now().toIso8601String(),
          'dirty': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (changed == 0) {
        return (failure: ValidationFailure('Catatan #$id tidak ditemukan.'));
      }
      return (failure: null);
    } catch (e) {
      return (failure: LocalFailure('Gagal memperbarui catatan: $e'));
    }
  }

  @override
  Future<({Failure? failure})> deleteNote(int id) async {
    try {
      final db = await _openDb();
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
      return (failure: null);
    } catch (e) {
      return (failure: LocalFailure('Gagal menghapus catatan: $e'));
    }
  }

  @override
  Future<({int? dirtyCount, Failure? failure})> countDirty() async {
    try {
      final db = await _openDb();
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE dirty = 1',
      );
      return (
        dirtyCount: (rows.first['c'] as num?)?.toInt() ?? 0,
        failure: null,
      );
    } catch (e) {
      return (
        dirtyCount: null,
        failure: LocalFailure('Gagal menghitung catatan: $e'),
      );
    }
  }

  @override
  Future<({Failure? failure})> markAllSynced() async {
    try {
      final db = await _openDb();
      await db.update(_table, {'dirty': 0}, where: 'dirty = 1');
      return (failure: null);
    } catch (e) {
      return (failure: LocalFailure('Gagal menandai catatan tersinkron: $e'));
    }
  }
}
