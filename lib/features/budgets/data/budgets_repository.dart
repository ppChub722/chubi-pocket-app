import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/budget.dart';
import '../domain/budget_overview.dart';
import '../domain/budget_period.dart';
import '../domain/budget_scope.dart';

/// Thin Dio wrapper for `/v1/budgets` (spec §08/§3).
class BudgetsRepository {
  BudgetsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/budgets`. Defaults to active; can filter by period / scope.
  Future<List<Budget>> list({
    String status = 'active',
    BudgetPeriod? period,
    BudgetScope? scope,
    String? projectId,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/budgets',
        queryParameters: <String, dynamic>{
          'status': status,
          'period': ?period?.toJson(),
          'scope': ?scope?.toJson(),
          'project_id': ?projectId,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Budget.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Budget> getById(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/budgets/$id',
      );
      return Budget.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/budgets`. Server may reject with `DUPLICATE_BUDGET` or
  /// `INVALID_CATEGORY` — re-thrown as [ApiException] for the form to
  /// surface inline.
  Future<Budget> create(Budget draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/budgets',
        data: draft.toCreateJson(),
      );
      return Budget.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/budgets/:id`. Spec §3.4: `category_id` / `scope` /
  /// `project_id` are not editable.
  Future<Budget> update(Budget budget) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/budgets/${budget.id}',
        data: budget.toUpdateJson(),
      );
      return Budget.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/budgets/:id` — hard delete (spec §3.5).
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<void>('/budgets/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Budget> archive(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/budgets/$id/archive',
      );
      return Budget.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Budget> restore(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/budgets/$id/restore',
      );
      return Budget.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/budgets/overview` (spec §3.7) — aggregate summary across
  /// active budgets for a period + scope.
  Future<BudgetOverview> overview({
    BudgetPeriod period = BudgetPeriod.monthly,
    BudgetScope scope = BudgetScope.user,
    String? projectId,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/budgets/overview',
        queryParameters: <String, dynamic>{
          'period': period.toJson(),
          'scope': scope.toJson(),
          'project_id': ?projectId,
        },
      );
      return BudgetOverview.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
