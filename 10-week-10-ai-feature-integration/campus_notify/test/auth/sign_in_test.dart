import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/repositories/session_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith, this.nullSession = false});

  final Failure? failWith;

  /// Simulasi repository "boroskan" kontrak: session null TANPA failure.
  final bool nullSession;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (nullSession) {
      return (session: null, failure: null);
    }
    if (failWith != null) {
      return (session: null, failure: failWith);
    }
    return (
      session: AuthSession(
        accessToken: 'access-$email',
        refreshToken: 'refresh-$email',
      ),
      failure: null,
    );
  }

  @override
  Future<({String? accessToken, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    if (refreshToken.isEmpty) {
      return (
        accessToken: null,
        failure: const AuthFailure('Refresh token tidak tersedia'),
      );
    }
    return (accessToken: 'new-access', failure: null);
  }
}

class FakeSessionRepository implements SessionRepository {
  String? savedAccessToken;
  String? savedRefreshToken;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    savedAccessToken = accessToken;
    savedRefreshToken = refreshToken;
  }

  @override
  Future<String?> accessToken() async => savedAccessToken;

  @override
  Future<String?> refreshToken() async => savedRefreshToken;

  @override
  Future<bool> hasActiveSession() async => (savedAccessToken ?? '').isNotEmpty;

  @override
  Future<void> clear() async {
    savedAccessToken = null;
    savedRefreshToken = null;
  }
}

void main() {
  test(
    'SignIn menyimpan sesi ke SessionRepository saat login sukses',
    () async {
      final auth = FakeAuthRepository();
      final session = FakeSessionRepository();

      final result = await SignIn(
        auth,
        session,
      ).call(email: 'test@gmail.com', password: '123456');

      expect(result.failure, isNull);
      expect(session.savedAccessToken, 'access-test@gmail.com');
      expect(session.savedRefreshToken, 'refresh-test@gmail.com');
    },
  );

  test('SignIn meneruskan Failure validasi dan TIDAK menyimpan sesi', () async {
    final auth = FakeAuthRepository(
      failWith: const ValidationFailure('Email tidak valid'),
    );
    final session = FakeSessionRepository();

    final result = await SignIn(
      auth,
      session,
    ).call(email: 'bukan-email', password: '123456');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.failure!.message, 'Email tidak valid');
    expect(session.savedAccessToken, isNull);
  });

  test('SignIn tidak crash saat repository melanggar kontrak (session & failure dua-duanya null)', () async {
    final auth = FakeAuthRepository(nullSession: true);
    final session = FakeSessionRepository();

    final result = await SignIn(
      auth,
      session,
    ).call(email: 'test@gmail.com', password: '123456');

    // Guard eksplisit: user dapat pesan ramah, bukan crash null-check.
    expect(result.failure, isA<AuthFailure>());
    expect(session.savedAccessToken, isNull);
  });

  test('Refresh menghasilkan token baru lewat kontrak domain', () async {
    final auth = FakeAuthRepository();
    final result = await auth.refresh('refresh-token');

    expect(result.failure, isNull);
    expect(result.accessToken, 'new-access');
  });
}
