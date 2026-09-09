import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Stat {
  const Stat(this.label, this.value);

  final String label;
  final String value;
}

class StatsNotifier extends AsyncNotifier<List<Stat>> {
  @override
  Future<List<Stat>> build() async {
    await Future.delayed(const Duration(seconds: 2));

    if (Random().nextDouble() < 0.3) {
      throw Exception('Gagal memuat statistik');
    }

    return const [
      Stat('Pengguna aktif', '1.240'),
      Stat('Pesanan hari ini', '86'),
      Stat('Pendapatan', 'Rp4.500.000'),
    ];
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<Stat>>(StatsNotifier.new);
