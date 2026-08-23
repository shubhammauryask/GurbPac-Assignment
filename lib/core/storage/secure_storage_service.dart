import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyUserSession = 'user_session';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(
        key: _keyTokenExpiry, value: expiresAt.toIso8601String());
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<DateTime?> getTokenExpiry() async {
    final val = await _storage.read(key: _keyTokenExpiry);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  Future<void> saveUserSession(String userJson) async {
    await _storage.write(key: _keyUserSession, value: userJson);
  }

  Future<String?> getUserSession() async {
    return await _storage.read(key: _keyUserSession);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiry);
    await _storage.delete(key: _keyUserSession);
  }
}
