import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../messaging/push_service.dart';

/// Riverpod Provider untuk Singleton [PushService]
final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// StreamProvider untuk mendengarkan navigasi deep-link dari Notifikasi (Tanpa BuildContext)
final pushNavigationStreamProvider = StreamProvider<String>((ref) {
  final pushService = ref.watch(pushServiceProvider);
  return pushService.navigationStream;
});
