import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak domain untuk data pengumuman.
/// Sumber datanya (JSONPlaceholder / mock / SQLite cache) urusan data layer.
abstract class AnnouncementRepository {
  Future<({Announcement? announcement, Failure? failure})>
  fetchAnnouncement(String id);

  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements();
}
