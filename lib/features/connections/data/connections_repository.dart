import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/user.dart';
import '../domain/connection.dart';

/// The outside apps (0.4.2 1b): one call per page open, one per button.
/// Every write answers the final row (or my profile), never re-fetch.
class ConnectionsRepository {
  ConnectionsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Connection _row(Response<Map<String, dynamic>> res) =>
      Connection.fromJson(res.data!);

  /// Every provider, in order telegram, line, google.
  Future<List<Connection>> list() => _call(() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/connections');
    return [
      for (final r in (res.data?['data'] as List?) ?? const [])
        if (r is Map) Connection.fromJson(r.cast<String, dynamic>()),
    ];
  });

  /// One provider (the connection page; re-read on app resume after linking).
  Future<Connection> get(String provider) => _call(
    () async => _row(
      await _client.dio.get<Map<String, dynamic>>('/connections/$provider'),
    ),
  );

  /// เชื่อม / เปลี่ยนบัญชี: the URL to open in the outside app (409
  /// CONNECTION_UNAVAILABLE when it can't be linked now).
  Future<ConnectionLinkStart> startLink(String provider) => _call(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/connections/$provider/link',
    );
    return ConnectionLinkStart.fromJson(res.data!);
  });

  /// ยกเลิกการเชื่อม (409 LAST_LOGIN_METHOD for a passwordless account's last
  /// linked app).
  Future<Connection> unlink(String provider) => _call(
    () async => _row(
      await _client.dio.delete<Map<String, dynamic>>('/connections/$provider'),
    ),
  );

  /// One switch = one call: `{key: on}`.
  Future<Connection> setPermissions(
    String provider,
    Map<String, bool> permissions,
  ) => _call(
    () async => _row(
      await _client.dio.patch<Map<String, dynamic>>(
        '/connections/$provider/permissions',
        data: permissions,
      ),
    ),
  );

  /// นำเข้า / อัปเดต the picture from the app (404 NO_PHOTO, 409 NOT_LINKED,
  /// 502 PROVIDER_ERROR). It does not pick it as my avatar.
  Future<Connection> importPhoto(String provider) => _call(
    () async => _row(
      await _client.dio.post<Map<String, dynamic>>(
        '/connections/$provider/photo',
      ),
    ),
  );

  /// ลบ one stored picture by source (upload / telegram / …); answers my
  /// profile (a picked source falls back to the icon).
  Future<User> deleteAvatar(String source) => _call(() async {
    final res = await _client.dio.delete<Map<String, dynamic>>(
      '/avatars/$source',
    );
    return User.fromJson(res.data!);
  });
}
