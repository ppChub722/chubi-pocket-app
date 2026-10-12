import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/me_counts.dart';

/// `GET /me/counts` — one call for badges + hub counts.
class MeCountsRepository {
  MeCountsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<MeCounts> fetch() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/me/counts');
      return MeCounts.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
