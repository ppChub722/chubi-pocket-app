import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/dashboard.dart';

/// Thin Dio wrapper for `GET /v1/dashboard` (contract §4) — the whole
/// home screen in one request.
class DashboardRepository {
  DashboardRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// [month] is any day in the wanted month; null = the current month
  /// (resolved by the BE in the user's timezone).
  Future<Dashboard> get({DateTime? month}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/dashboard',
        queryParameters: <String, dynamic>{
          if (month != null)
            'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        },
      );
      return Dashboard.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
