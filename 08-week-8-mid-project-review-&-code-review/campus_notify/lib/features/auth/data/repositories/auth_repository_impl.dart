import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementasi kontrak auth. Saat ini mock (sama seperti minggu 6);
/// siap diganti Firebase Auth / Dio tanpa menyentuh domain & presentation.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!email.contains('@')) {
      return (
        session: null,
        failure: const ValidationFailure('Email tidak valid'),
      );
    }

    if (password.length < 6) {
      return (
        session: null,
        failure: const ValidationFailure('Password minimal 6 karakter'),
      );
    }

    return (
      session: AuthSession(
        accessToken: 'access-token-$email',
        refreshToken: 'refresh-token-$email',
      ),
      failure: null,
    );
  }

  @override
  Future<({String? accessToken, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (refreshToken.isEmpty) {
      return (
        accessToken: null,
        failure: const AuthFailure('Refresh token tidak tersedia'),
      );
    }

    return (
      accessToken:
          'new-access-token-${DateTime.now().millisecondsSinceEpoch}',
      failure: null,
    );
  }
}
