import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/app_version_info.dart';

/// `GET /app/version` — public, never blocked by the version gate itself.
class AppVersionRepository {
  AppVersionRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<AppVersionInfo> fetch() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/app/version');
      final body = res.data ?? const <String, dynamic>{};
      final data = body['data'];
      return AppVersionInfo.fromJson(
        data is Map<String, dynamic> ? data : body,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
