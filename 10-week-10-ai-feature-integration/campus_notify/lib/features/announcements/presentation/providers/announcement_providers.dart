import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement.dart';

/// Wiring DI fitur announcements — satu-satunya tempat layer-layer disatukan.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => const AnnouncementRepositoryImpl(),
);

final getAnnouncementProvider = Provider<GetAnnouncement>(
  (ref) => GetAnnouncement(ref.watch(announcementRepositoryProvider)),
);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref
      .watch(announcementRepositoryProvider)
      .fetchAnnouncements();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcements;
});

final announcementDetailProvider = FutureProvider.family<Announcement, String>((
  ref,
  id,
) async {
  final result = await ref.watch(getAnnouncementProvider).call(id: id);
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcement!;
});
