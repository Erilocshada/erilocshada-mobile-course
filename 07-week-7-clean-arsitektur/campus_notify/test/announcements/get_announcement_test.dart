import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository PALSU — domain diuji murni, tanpa SQLite/Dio/Firebase.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({Announcement? announcement, Failure? failure})>
  fetchAnnouncement(String id) async {
    if (fail) {
      return (
        announcement: null,
        failure: const NetworkFailure('offline (simulasi)'),
      );
    }
    final found = items.where((a) => a.id == id);
    if (found.isEmpty) {
      return (
        announcement: null,
        failure: NetworkFailure('Pengumuman #$id tidak ditemukan.'),
      );
    }
    return (announcement: found.first, failure: null);
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const NetworkFailure('offline (simulasi)'),
      );
    }
    return (announcements: items, failure: null);
  }
}

void main() {
  final announcement = Announcement(
    id: '1',
    title: 'Pengumuman #1',
    body: 'Jadwal UTS telah diumumkan.',
    publishedAt: DateTime(2026, 10, 1),
  );

  test('GetAnnouncement meneruskan data dari repository', () async {
    final repo = FakeAnnouncementRepository(items: [announcement]);
    final result = await GetAnnouncement(repo).call(id: '1');

    expect(result.failure, isNull);
    expect(result.announcement, isNotNull);
    expect(result.announcement!.title, 'Pengumuman #1');
  });

  test('GetAnnouncement meneruskan failure tanpa melempar exception', () async {
    final repo = FakeAnnouncementRepository(fail: true);
    final result = await GetAnnouncement(repo).call(id: '1');

    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, 'offline (simulasi)');
    expect(result.announcement, isNull);
  });

  test('GetAnnouncement menolak id kosong lewat ValidationFailure', () async {
    final repo = FakeAnnouncementRepository(items: [announcement]);
    final result = await GetAnnouncement(repo).call(id: '   ');

    expect(result.failure, isA<ValidationFailure>());
  });
}
