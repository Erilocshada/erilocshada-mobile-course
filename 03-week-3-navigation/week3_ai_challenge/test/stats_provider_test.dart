import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_ai_challenge/providers/stats_provider.dart';

class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  test('notifier menghasilkan tiga statistik saat berhasil', () async {
    final container = ProviderContainer(
      overrides: [statsRandomProvider.overrideWithValue(FixedRandom(0.5))],
    );
    addTearDown(container.dispose);

    final stats = await container.read(statsProvider.future);

    expect(stats, hasLength(3));
    expect(stats.first.label, 'Pengguna aktif');
  });

  test('notifier menghasilkan error saat pengambilan data gagal', () async {
    final container = ProviderContainer(
      overrides: [statsRandomProvider.overrideWithValue(FixedRandom(0.1))],
    );
    addTearDown(container.dispose);

    final errorState = Completer<AsyncValue<List<Stat>>>();
    final subscription = container.listen(statsProvider, (previous, next) {
      if (next.hasError && !errorState.isCompleted) {
        errorState.complete(next);
      }
    });
    addTearDown(subscription.close);

    final state = await errorState.future.timeout(const Duration(seconds: 3));

    expect(state.error.toString(), contains('Gagal memuat statistik'));
  });
}
