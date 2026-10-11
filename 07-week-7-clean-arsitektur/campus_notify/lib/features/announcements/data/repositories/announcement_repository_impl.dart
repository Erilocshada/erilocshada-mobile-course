import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Sumber data mock (siap ditukar Dio + ApiClient tanpa sentuh domain/UI).
/// Data yang ditampilkan identik dengan minggu 6: pengumuman UTS.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();

  static const List<Map<String, dynamic>> _mockJson = [
    {
      'id': '1',
      'title': 'Pengumuman #1',
      'body': 'Jadwal Ujian Tengah Semester telah diumumkan. '
          'Silakan cek jadwal melalui sistem akademik.',
      'published_at': '2026-10-01T08:00:00Z',
    },
  ];

  @override
  Future<({Announcement? announcement, Failure? failure})>
  fetchAnnouncement(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final json = _mockJson.firstWhere((a) => a['id'] == id);
      return (
        announcement: AnnouncementModel.fromJson(json).toEntity(),
        failure: null,
      );
    } catch (_) {
      return (
        announcement: null,
        failure: NetworkFailure('Pengumuman #$id tidak ditemukan.'),
      );
    }
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return (
        announcements: _mockJson
            .map((j) => AnnouncementModel.fromJson(j).toEntity())
            .toList(),
        failure: null,
      );
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }
}
