import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/pending_transaction.dart';

/// `/v1/pending-transactions` — drafts waiting to be confirmed.
class PendingRepository {
  PendingRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// The page's one call: drafts + the server's `summary`.
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

  /// Adds one or many manual drafts (all or nothing); answers the new drafts
  /// and the server's `summary` over the whole list.
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

  /// Replaces the draft (clears its last submit error); answers the draft and
  /// the server's `summary` (a sibling key of the draft's own fields).
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

  /// Discards one draft.
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

  /// Discards many in one call (the API takes 1..100 ids; a longer list goes
  /// in chunks).
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

  /// "Confirm everything ready" — one call; the server picks the drafts
  /// whose `needs_input` is empty. Answers like [submit].
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

  /// Confirms one draft (same answer as [submit] with that id).
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
