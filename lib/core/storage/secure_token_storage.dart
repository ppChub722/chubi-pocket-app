import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] with a typed API for the auth token.
///
/// On mobile this writes to the OS keystore (Android Keystore / iOS Keychain).
/// On web it falls back to `localStorage` — acknowledged risk, mitigated in
/// Phase 2+ by short-lived access tokens.
///
/// Non-sensitive prefs (theme id, locale, font id) live in `shared_preferences`
/// instead — see `features/preferences/presentation/cubit/`.
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
