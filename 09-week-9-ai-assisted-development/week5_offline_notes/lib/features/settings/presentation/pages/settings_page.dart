import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);
    final isDark = darkModeAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Ubah tema aplikasi ke Mode Gelap'),
            value: isDark,
            onChanged: (val) {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Terakhir Dibuka'),
            subtitle: Text(_lastOpenedLabel(lastOpenedAsync)),
          ),
        ],
      ),
    );
  }

  String _lastOpenedLabel(AsyncValue<String?> async) => async.when(
    data: (val) => (val != null && val.isNotEmpty) ? val : 'Belum tercatat',
    loading: () => 'Memuat...',
    error: (err, _) => 'Gagal memuat',
  );
}
