import '../../../../core/failures.dart';
import '../entities/note.dart';

/// Kontrak domain untuk catatan.
/// Sumber datanya (SQLite hari ini, API nanti) urusan data layer —
/// presentation tidak boleh tahu bedanya.
///
/// Semua method mengembalikan record bernamed-field `({..., Failure? failure})`,
/// mengikuti pola minggu 7/8: kegagalan adalah nilai, bukan exception.
abstract class NoteRepository {
  Future<({List<Note>? notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body,
  });

  /// Memperbarui catatan yang sudah ada [id]. Mengembalikan failure bila
  /// tidak ada baris yang cocok.
  Future<({Failure? failure})> updateNote({
    required int id,
    required String title,
    String body,
  });

  Future<({Failure? failure})> deleteNote(int id);

  Future<({int? dirtyCount, Failure? failure})> countDirty();

  Future<({Failure? failure})> markAllSynced();
}
