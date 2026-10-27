import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case: ambil satu pengumuman + aturan bisnis validasi id.
class GetAnnouncement {
  const GetAnnouncement(this._repository);

  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call({
    required String id,
  }) async {
    if (id.trim().isEmpty) {
      return (
        announcement: null,
        failure: const ValidationFailure('ID pengumuman tidak valid.'),
      );
    }

    return _repository.fetchAnnouncement(id.trim());
  }
}
