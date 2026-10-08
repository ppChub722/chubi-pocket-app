import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/pending_transaction.dart';

/// `/v1/pending-transactions` — drafts waiting to be confirmed.
class PendingRepository {
  PendingRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<PendingTransaction>> list() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>('/pending-transactions');
      return ((res.data!['data'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PendingTransaction.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Adds one or many manual drafts (all or nothing).
  Future<List<PendingTransaction>> create(List<PendingDraft> drafts) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/pending-transactions',
        data: <String, dynamic>{
          'items': [
            for (final d in drafts) {'draft': d.toJson()},
          ],
        },
      );
      return ((res.data!['data'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PendingTransaction.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Replaces the draft (clears its last submit error).
  Future<PendingTransaction> update(String id, PendingDraft draft) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/pending-transactions/$id',
        data: <String, dynamic>{'draft': draft.toJson()},
      );
      return PendingTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<dynamic>('/pending-transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Each draft independently — see [PendingSubmitResult].
  Future<PendingSubmitResult> submit(List<String> ids) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/pending-transactions/submit',
        data: <String, dynamic>{'ids': ids},
      );
      return PendingSubmitResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
