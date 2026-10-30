import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';

/// Fake untuk seluruh test fitur notes.
///
/// Minggu 5 mendefinisikannya sebagai `extends NoteRepository` terhadap kelas
/// konkret, yang memaksa test ikut membawa `_openDb`. Sekarang kontraknya
/// abstract di domain, jadi fake cukup `implements` — dan SQLite tidak masuk
/// ke test sama sekali.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({List<Note>? notes, this.failOnFetch = false})
    : notes = notes ?? <Note>[];

  final List<Note> notes;

  /// Meniru kegagalan sumber data: kontrak mengembalikan [Failure], bukan
  /// melempar exception.
  final bool failOnFetch;

  int _nextId = 100;

  /// Urutan tampil mengikuti repository impl: terbaru lebih dulu.
  List<Note> get _sorted =>
      [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<({List<Note>? notes, Failure? failure})> fetchNotes() async {
    if (failOnFetch) {
      return (notes: null, failure: const LocalFailure('db locked (simulasi)'));
    }
    return (notes: _sorted, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: _nextId++,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<({Failure? failure})> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index == -1) {
      return (failure: ValidationFailure('Catatan #$id tidak ditemukan.'));
    }
    notes[index] = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    return (failure: null);
  }

  @override
  Future<({Failure? failure})> deleteNote(int id) async {
    notes.removeWhere((n) => n.id == id);
    return (failure: null);
  }

  @override
  Future<({int? dirtyCount, Failure? failure})> countDirty() async =>
      (dirtyCount: notes.where((n) => n.dirty).length, failure: null);

  @override
  Future<({Failure? failure})> markAllSynced() async {
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      notes[i] = Note(
        id: n.id,
        title: n.title,
        body: n.body,
        updatedAt: n.updatedAt,
        dirty: false,
      );
    }
    return (failure: null);
  }
}
