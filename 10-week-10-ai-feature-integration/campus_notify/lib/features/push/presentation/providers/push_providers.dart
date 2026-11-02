import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/push_service.dart';
import '../../domain/repositories/push_repository.dart';

/// Presentation hanya mengenal abstraksi [PushRepository].
/// PushService (Firebase/Dio/SecureStorage) dirangkai di sini — satu-satunya
/// titik wiring, mudah di-overwrite dengan fake saat test.
final pushRepositoryProvider = Provider<PushRepository>((ref) {
  final service = PushServiceImpl();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StreamProvider untuk mendengarkan navigasi deep-link dari Notifikasi
/// (Tanpa BuildContext).
final pushNavigationStreamProvider = StreamProvider<String>((ref) {
  final pushRepository = ref.watch(pushRepositoryProvider);
  return pushRepository.navigationStream;
});
