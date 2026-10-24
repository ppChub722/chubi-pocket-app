import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger/app_logger.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _kAuthToken = 'auth_token';

  final FlutterSecureStorage _storage;

  /// A store that can't be read (e.g. restored from a backup after a
  /// reinstall, encrypted with a key the device no longer has) is wiped and
  /// read as signed out, instead of failing every start.
  Future<String?> readAuthToken() async {
    try {
      return await _storage.read(key: _kAuthToken);
    } catch (e) {
      AppLogger.instance.warn(
        'auth.token_unreadable',
        fields: {'error': '$e', 'action': 'storage wiped, signed out'},
      );
      try {
        await _storage.deleteAll();
      } catch (_) {
        /* best-effort */
      }
      return null;
    }
  }

  Future<void> writeAuthToken(String token) =>
      _storage.write(key: _kAuthToken, value: token);

  Future<void> clearAuthToken() => _storage.delete(key: _kAuthToken);
}
