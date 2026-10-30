import '../../../../core/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

/// Use case: tambah catatan, dengan aturan bisnis validasi judul.
class AddNote {
  const AddNote(this._repository);

  final NoteRepository _repository;

  Future<({Note? note, Failure? failure})> call({
    required String title,
    String body = '',
  }) async {
    if (title.trim().isEmpty) {
      return (
        note: null,
        failure: const ValidationFailure('Judul tidak boleh kosong.'),
      );
    }

    return _repository.addNote(title: title.trim(), body: body.trim());
  }
}
