import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/archived_hub.dart';

class ArchivedRepository {
  ArchivedRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<ArchivedHub> fetch() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/me/archived');
      return ArchivedHub.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> restore(ArchivedKind kind, String id) async {
    try {
      final dio = _client.dio;
      switch (kind) {
        case ArchivedKind.wallets:
          await dio.post<void>('/accounts/$id/restore');
        case ArchivedKind.budgets:
          await dio.post<void>('/budgets/$id/restore');
        case ArchivedKind.goals:
          await dio.post<void>('/saving-goals/$id/restore');
        case ArchivedKind.events:
          await dio.post<void>('/projects/$id/restore');
        case ArchivedKind.contacts:
          await dio.post<void>('/contacts/$id/restore');
        case ArchivedKind.recurring:
          await dio.post<void>('/recurring/$id/restore');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
