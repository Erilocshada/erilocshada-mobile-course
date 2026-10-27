/// Entity murni — tanpa mapping (toMap/fromMap/toJson) dan tanpa import framework.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
