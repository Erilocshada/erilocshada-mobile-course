/// Kontrak domain untuk penyimpanan sesi aktif.
/// Implementasinya (flutter_secure_storage) hidup di data layer,
/// sehingga use case dan notifier bisa diuji tanpa plugin.
abstract class SessionRepository {
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> accessToken();

  Future<String?> refreshToken();

  Future<bool> hasActiveSession();

  Future<void> clear();
}
