import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Infra detail: penyimpanan API key AI di secure storage (bukan kode sumber).
/// Pola sama dengan TokenStore minggu 7 — tidak diimpor presentation.
class AiKeyStore {
  AiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _apiKeyKey = 'ai_api_key';

  Future<void> saveKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key.trim());
  }

  Future<String?> getKey() async {
    final key = await _storage.read(key: _apiKeyKey);
    if (key == null || key.trim().isEmpty) return null;
    return key.trim();
  }

  Future<void> clear() async {
    await _storage.delete(key: _apiKeyKey);
  }
}
