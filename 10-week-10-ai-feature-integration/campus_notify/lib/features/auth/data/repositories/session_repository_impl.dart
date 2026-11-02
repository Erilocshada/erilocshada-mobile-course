import '../../domain/repositories/session_repository.dart';
import '../token_store.dart';

/// Memenuhi kontrak SessionRepository memakai FlutterSecureStorage (via TokenStore).
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) {
    return _tokenStore.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<String?> accessToken() => _tokenStore.getAccessToken();

  @override
  Future<String?> refreshToken() => _tokenStore.getRefreshToken();

  @override
  Future<bool> hasActiveSession() async {
    final token = await _tokenStore.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clear() => _tokenStore.clear();
}
