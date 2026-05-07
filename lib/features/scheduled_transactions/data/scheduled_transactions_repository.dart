import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/scheduled_enums.dart';
import '../domain/scheduled_history.dart';
import '../domain/scheduled_transaction.dart';
import '../domain/scheduled_upcoming.dart';

/// Thin Dio wrapper for `/v1/scheduled-transactions` (spec §11/§3).
class ScheduledTransactionsRepository {
  ScheduledTransactionsRepository({required ApiClient client})
      : _client = client;

  final ApiClient _client;

  /// `GET /v1/scheduled-transactions`. Active by default.
  Future<List<ScheduledTransaction>> list({
    String status = 'active',
    ScheduledEntryType? entryType,
    ScheduledTransactionType? type,
    String? accountId,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/scheduled-transactions',
        queryParameters: <String, dynamic>{
          'status': status,
          'entry_type': ?entryType?.toJson(),
          'type': ?type?.toJson(),
          'account_id': ?accountId,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(ScheduledTransaction.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ScheduledTransaction> getById(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/scheduled-transactions/$id',
      );
      return ScheduledTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/scheduled-transactions`. Server validates installment-only
  /// fields based on `entry_type` (spec §3.1).
  Future<ScheduledTransaction> create(ScheduledTransaction draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/scheduled-transactions',
        data: draft.toCreateJson(),
      );
      return ScheduledTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/scheduled-transactions/:id`. Spec §3.5: `type`, `entry_type`,
  /// `status` are not editable. Edits affect future cycles only.
  Future<ScheduledTransaction> update(ScheduledTransaction entry) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/scheduled-transactions/${entry.id}',
        data: entry.toUpdateJson(),
      );
      return ScheduledTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/scheduled-transactions/:id` — hard delete (spec §3.6).
  /// Generated transactions stay (FK ON DELETE SET NULL).
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<void>('/scheduled-transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ScheduledTransaction> pause(String id) =>
      _transition(id, 'pause');
  Future<ScheduledTransaction> resume(String id) =>
      _transition(id, 'resume');
  Future<ScheduledTransaction> cancel(String id) =>
      _transition(id, 'cancel');

  /// Private dispatcher for the three lifecycle endpoints. Server may
  /// return `400 INVALID_TRANSITION` if the current status doesn't allow
  /// the requested move (spec §3.7).
  Future<ScheduledTransaction> _transition(String id, String action) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/scheduled-transactions/$id/$action',
      );
      return ScheduledTransaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/scheduled-transactions/:id/generate-now` (spec §3.8).
  /// Phase 1c: manual trigger; Phase 3+ replaced with hourly cron.
  Future<GenerateNowResult> generateNow(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/scheduled-transactions/$id/generate-now',
      );
      return GenerateNowResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/scheduled-transactions/:id/history` (spec §3.9).
  Future<ScheduledHistory> history(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/scheduled-transactions/$id/history',
      );
      return ScheduledHistory.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/scheduled-transactions/upcoming?days=N` (spec §3.3).
  Future<ScheduledUpcoming> upcoming({int days = 7}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/scheduled-transactions/upcoming',
        queryParameters: <String, dynamic>{'days': days},
      );
      return ScheduledUpcoming.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
