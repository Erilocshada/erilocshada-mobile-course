import 'dart:async';

import 'package:campus_notify/features/auth/data/token_store.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_notify/features/push/domain/repositories/push_repository.dart';
import 'package:campus_notify/features/push/presentation/providers/push_providers.dart';
import 'package:campus_notify/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// PushRepository palsu — smoke test tidak boleh menyentuh Firebase asli.
class FakePushRepository implements PushRepository {
  final _controller = StreamController<String>.broadcast();

  @override
  Future<void> start() async {}

  @override
  Stream<String> get navigationStream => _controller.stream;

  @override
  Future<void> subscribeTopic(String topic) async {}

  @override
  Future<void> unsubscribeTopic(String topic) async {}

  @override
  Future<String?> deviceToken() async => 'fake-token';

  @override
  void dispose() => _controller.close();
}

/// TokenStore palsu di memori — mengganti FlutterSecureStorage karena plugin
/// asli melempar MissingPluginException di environment test.
class FakeTokenStore extends TokenStore {
  final Map<String, String> _store = {};

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _store['access_token'] = accessToken;
    _store['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _store['access_token'];

  @override
  Future<String?> getRefreshToken() async => _store['refresh_token'];

  @override
  Future<void> clear() async => _store.clear();
}

void main() {
  testWidgets('CampusNotifyApp smoke test', (WidgetTester tester) async {
    // Bangun app dengan infra diganti fake lewat DI — inilah kegunaan titik
    // wiring tunggal yang dibangun minggu 7.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushRepositoryProvider.overrideWithValue(FakePushRepository()),
          tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        ],
        child: const CampusNotifyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tidak ada sesi aktif -> router harus membuang user ke halaman login,
    // dan tidak boleh ada exception yang lolos.
    expect(find.text('Silakan login untuk melanjutkan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
