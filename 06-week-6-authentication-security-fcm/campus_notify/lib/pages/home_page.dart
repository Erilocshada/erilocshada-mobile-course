import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await ref
                  .read(authProvider.notifier)
                  .logout();
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 100,
              ),

              const SizedBox(height: 24),

              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Campus Notification App',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.campaign,
                  ),
                  title: const Text(
                    'Pengumuman Kampus',
                  ),
                  subtitle: const Text(
                    'Lihat pengumuman terbaru',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),
                  onTap: () {
                    // Akan kita hubungkan ke
                    // announcement page
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}