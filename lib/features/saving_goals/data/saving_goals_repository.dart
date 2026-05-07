import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/saving_allocation_summary.dart';
import '../domain/saving_goal.dart';

/// Thin Dio wrapper for `/v1/saving-goals` (spec §09/§3).
///
/// Pure data layer — translates [DioException] into [ApiException] and
/// parses JSON into [SavingGoal]. State + caching live in
/// `SavingGoalsCubit`.
class SavingGoalsRepository {
  SavingGoalsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/saving-goals`. Default returns active goals; pass
  /// `status: 'all'` to include archived in the user's history view.
  Future<List<SavingGoal>> list({
    String status = 'active',
    String? accountId,
    bool? isCompleted,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/saving-goals',
        queryParameters: <String, dynamic>{
          'status': status,
          'account_id': ?accountId,
          'is_completed': ?isCompleted,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(SavingGoal.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SavingGoal> getById(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/saving-goals/$id',
      );
      return SavingGoal.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/saving-goals`. Server may reject with `ALLOCATION_EXCEEDED`
  /// or `ACCOUNT_NOT_OWNED` — both come back as [ApiException] with the
  /// API message which the form page surfaces inline.
  Future<SavingGoal> create(SavingGoal draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/saving-goals',
        data: draft.toCreateJson(),
      );
      return SavingGoal.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/saving-goals/:id`. Spec §3.4: `linked_account_id` is not
  /// editable; allocation changes re-check sum ≤ 100.
  Future<SavingGoal> update(SavingGoal goal) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/saving-goals/${goal.id}',
        data: goal.toUpdateJson(),
      );
      return SavingGoal.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/saving-goals/:id` — hard delete (spec §3.5). Always
  /// permitted; account + transactions untouched.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<void>('/saving-goals/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/saving-goals/:id/archive` — frees allocation capacity.
  Future<SavingGoal> archive(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/saving-goals/$id/archive',
      );
      return SavingGoal.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/saving-goals/:id/restore` — re-checks allocation sum
  /// against the goal's stored `allocation_pct`; may return
  /// `ALLOCATION_EXCEEDED`.
  Future<SavingGoal> restore(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/saving-goals/$id/restore',
      );
      return SavingGoal.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/accounts/:id/saving-allocations` (spec §3.7) — pie helper.
  /// Returns the per-account allocation breakdown across active goals.
  Future<SavingAllocationSummary> allocationsFor(String accountId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$accountId/saving-allocations',
      );
      return SavingAllocationSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
