import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

/// Kontrak domain: domain menentukan APA yang dibutuhkan,
/// data layer yang menentukan BAGAIMANA (Dio / Firebase Auth / mock).
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? accessToken, Failure? failure})> refresh(
    String refreshToken,
  );
}
