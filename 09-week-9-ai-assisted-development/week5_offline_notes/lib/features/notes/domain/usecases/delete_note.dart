import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Use case: hapus catatan berdasarkan id.
class DeleteNote {
  const DeleteNote(this._repository);

  final NoteRepository _repository;

  Future<({Failure? failure})> call(int id) {
    if (id <= 0) {
      return Future.value((
        failure: const ValidationFailure('ID catatan tidak valid.'),
      ));
    }

    return _repository.deleteNote(id);
  }
}
