import '../../../../core/failures.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_repository.dart';

/// Use case: SATU operasi bisnis yang menggabungkan >1 repository —
/// login ke endpoint auth lalu menyimpan sesi aktif.
/// Inilah alasan use case ini bukan over-engineering (lihat docs/AI_CHALLENGE.md).
class SignIn {
  const SignIn(this._authRepository, this._sessionRepository);

  final AuthRepository _authRepository;
  final SessionRepository _sessionRepository;

  Future<({Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    if (result.failure != null) {
      return (failure: result.failure);
    }

    final session = result.session!;
    await _sessionRepository.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    return (failure: null);
  }
}
