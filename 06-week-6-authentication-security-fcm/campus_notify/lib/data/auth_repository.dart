class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!email.contains('@')) {
      throw Exception(
        'Email tidak valid',
      );
    }

    if (password.length < 6) {
      throw Exception(
        'Password minimal 6 karakter',
      );
    }

    return AuthSession(
      accessToken: 'access-token-$email',
      refreshToken: 'refresh-token-$email',
    );
  }

  Future<String> refresh(
      String refreshToken,
      ) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (refreshToken.isEmpty) {
      throw Exception(
        'Refresh token tidak tersedia',
      );
    }

    return 'new-access-token-${DateTime.now().millisecondsSinceEpoch}';
  }
}