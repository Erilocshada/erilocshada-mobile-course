import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Use case: sinkronkan catatan yang belum tersinkron.
///
/// Dulu berupa fungsi top-level `syncNotes()` di `lib/data/sync.dart`.
/// Aturan orkestrasinya (hanya kirim bila ada yang dirty, lalu tandai synced)
/// adalah logika bisnis, jadi tempatnya di domain. Ia hanya bergantung pada
/// kontrak abstract [NoteRepository], sehingga bisa diuji tanpa SQLite.
///
/// Transportnya masih simulasi: `Future.delayed` di bawah adalah placeholder
/// untuk panggilan jaringan, dan satu-satunya alasan fungsi ini ada.
class SyncNotes {
  const SyncNotes(this._repository);

  final NoteRepository _repository;

  Future<({int? syncedCount, Failure? failure})> call() async {
    final counted = await _repository.countDirty();
    if (counted.failure != null) {
      return (syncedCount: null, failure: counted.failure);
    }

    final dirtyCount = counted.dirtyCount ?? 0;
    if (dirtyCount == 0) {
      return (syncedCount: 0, failure: null);
    }

    await Future.delayed(const Duration(seconds: 1));

    final marked = await _repository.markAllSynced();
    if (marked.failure != null) {
      return (syncedCount: null, failure: marked.failure);
    }

    return (syncedCount: dirtyCount, failure: null);
  }
}
