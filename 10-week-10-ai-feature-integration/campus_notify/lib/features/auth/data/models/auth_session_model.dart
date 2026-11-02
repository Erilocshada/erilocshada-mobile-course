import '../../domain/entities/auth_session.dart';

/// Model = representasi data luar (JSON dari backend). Mapping HANYA di sini.
/// Saat pindah ke Firebase Auth sungguhan, response server di-parse lewat kelas ini.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      accessToken:
          json['access_token'] as String? ??
          json['accessToken'] as String? ??
          '',
      refreshToken:
          json['refresh_token'] as String? ??
          json['refreshToken'] as String? ??
          '',
    );
  }

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };

  AuthSession toEntity() =>
      AuthSession(accessToken: accessToken, refreshToken: refreshToken);
}
