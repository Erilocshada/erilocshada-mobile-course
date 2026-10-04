import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isSubscribed = true;

  @override
  Widget build(BuildContext context) {
    final pushService = ref.watch(pushServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Campus Notification App',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Card Pengumuman
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const Text('Pengumuman Kampus'),
                  subtitle: const Text('Lihat pengumuman #1'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go(RoutePaths.pengumumanDetail.replaceFirst(':id', '1'));
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Switch Topic Subscription ('pengumuman-kampus')
              SwitchListTile(
                title: const Text('Topik Pengumuman Kampus'),
                subtitle: Text(
                  _isSubscribed
                      ? 'Terdaftar di topik pengumuman-kampus'
                      : 'Tidak terdaftar',
                ),
                value: _isSubscribed,
                onChanged: (value) async {
                  setState(() {
                    _isSubscribed = value;
                  });

                  if (value) {
                    await pushService.subscribeTopic('pengumuman-kampus');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil subscribe pengumuman-kampus'),
                        ),
                      );
                    }
                  } else {
                    await pushService.unsubscribeTopic('pengumuman-kampus');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil unsubscribe pengumuman-kampus'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}