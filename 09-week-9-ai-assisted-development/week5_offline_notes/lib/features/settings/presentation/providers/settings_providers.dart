import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_settings_repository_impl.dart';
import '../../domain/repositories/app_settings_repository.dart';

/// Wiring DI fitur settings.
///
/// Provider ini dulu dideklarasikan di dalam `pages/settings_page.dart`,
/// sehingga halaman sekaligus menjadi tempat penyatuan layer. Sekarang
/// halaman hanya membaca state.
final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => AppSettingsRepositoryImpl(),
);

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(appSettingsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(appSettingsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(appSettingsRepositoryProvider).getLastOpened();
});
