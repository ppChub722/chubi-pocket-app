import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/pending_transaction.dart';

class PendingRepository {
  PendingRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<PendingList> list() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/pending-transactions',
      );
      return PendingList(
        items: ((res.data!['data'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PendingTransaction.fromJson)
            .toList(),
        summary: PendingSummary.maybe(res.data!['summary']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PendingList> create(List<PendingDraft> drafts) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/pending-transactions',
        data: <String, dynamic>{
          'items': [
            for (final d in drafts) {'draft': d.toJson()},
          ],
        },
      );
      return PendingList(
        items: ((res.data!['data'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(PendingTransaction.fromJson)
            .toList(),
        summary: PendingSummary.maybe(res.data!['summary']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PendingUpdated> update(String id, PendingDraft draft) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/pending-transactions/$id',
        data: <String, dynamic>{'draft': draft.toJson()},
      );
      return PendingUpdated(
        draft: PendingTransaction.fromJson(res.data!),
        summary: PendingSummary.maybe(res.data!['summary']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DiscardResult> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/pending-transactions/$id',
      );
      return DiscardResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DiscardResult> discard(List<String> ids) async {
    try {
      final discarded = <String>[];
      final skipped = <String>[];
      var remaining = 0;
      PendingSummary? summary;
      for (var i = 0; i < ids.length; i += 100) {
        final end = i + 100 > ids.length ? ids.length : i + 100;
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/pending-transactions/discard',
          data: <String, dynamic>{'ids': ids.sublist(i, end)},
        );
        final r = DiscardResult.fromJson(res.data!);
        discarded.addAll(r.discarded);
        skipped.addAll(r.skipped);
        remaining = r.remainingCount;
        summary = r.summary;
      }
      return DiscardResult(
        discarded: discarded,
        skipped: skipped,
        remainingCount: remaining,
        summary: summary,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<PendingSubmitResult> submitReady() async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/pending-transactions/submit-ready',
      );
      return PendingSubmitResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PendingSubmitResult> submitOne(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/pending-transactions/$id/submit',
      );
      return PendingSubmitResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
