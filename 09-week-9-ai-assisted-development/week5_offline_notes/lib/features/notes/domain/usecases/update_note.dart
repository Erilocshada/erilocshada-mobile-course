import '../../../../core/failures.dart';
import '../repositories/note_repository.dart';

/// Use case: perbarui catatan yang sudah ada.
///
/// Aturan bisnis yang menahan bug duplikat minggu 5: id harus merujuk baris
/// nyata (bukan 0, yang di aplikasi ini berarti "catatan baru") dan judul tidak
/// boleh kosong.
class UpdateNote {
  const UpdateNote(this._repository);

  final NoteRepository _repository;

  Future<({Failure? failure})> call({
    required int id,
    required String title,
    String body = '',
  }) async {
    if (id <= 0) {
      return (failure: const ValidationFailure('ID catatan tidak valid.'));
    }
    if (title.trim().isEmpty) {
      return (failure: const ValidationFailure('Judul tidak boleh kosong.'));
    }

    return _repository.updateNote(
      id: id,
      title: title.trim(),
      body: body.trim(),
    );
  }
}
