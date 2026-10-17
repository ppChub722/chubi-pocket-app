import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _kAuthToken = 'auth_token';

  final FlutterSecureStorage _storage;

  Future<String?> readAuthToken() => _storage.read(key: _kAuthToken);

  Future<void> writeAuthToken(String token) =>
      _storage.write(key: _kAuthToken, value: token);

  Future<void> clearAuthToken() => _storage.delete(key: _kAuthToken);
}
