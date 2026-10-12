import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';
import '../domain/budget_period.dart';

/// `/budgets` (openapi tag Budgets, spec 08 v2). Every write answers with the
/// budget page ([BudgetDetail]), so a page takes the new state from the
/// response and never re-fetches.
class BudgetsRepository {
  BudgetsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// The app-wide instance (provided in app.dart).
  static BudgetsRepository of(BuildContext context) =>
      context.read<BudgetsRepository>();

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `listBudgets`: the summary + each budget at its current period.
  Future<BudgetList> list({
    BudgetFilter filter = BudgetFilter.active,
    BudgetSort sort = BudgetSort.risk,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/budgets',
      queryParameters: {'status': filter.toJson(), 'sort': sort.toJson()},
    );
    return BudgetList.fromJson(res.data!);
  });

  /// `getBudget`: the whole page at [periodId] (default the current period).
  Future<BudgetDetail> get(String id, {String? periodId}) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/budgets/$id',
      queryParameters: {'period_id': ?periodId},
    );
    return BudgetDetail.fromJson(res.data!);
  });

  /// `createBudget`.
  Future<BudgetDetail> create(BudgetWrite write) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/budgets',
      data: write.toJson(),
    );
    return BudgetDetail.fromJson(res.data!);
  });

  /// `updateBudget`: the setup. [apply] (`following` | `all`) is the "ใช้กับ
  /// รอบไหน" answer on a recurring budget.
  Future<BudgetDetail> update(String id, BudgetWrite write, {String? apply}) =>
      _call((dio) async {
        final res = await dio.put<Map<String, dynamic>>(
          '/budgets/$id',
          data: write.toJson(apply: apply),
        );
        return BudgetDetail.fromJson(res.data!);
      });

  /// `updateBudgetPeriod` ("เฉพาะรอบนี้"): [amount] null = back to the base
  /// amount. The page comes back at that period.
  Future<BudgetDetail> updatePeriod(
    String id,
    String periodId, {
    required double? amount,
    required String? note,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/budgets/$id/periods/$periodId',
      data: {'amount': amount, 'note': note},
    );
    return BudgetDetail.fromJson(res.data!);
  });

  /// `listBudgetPeriods`: newest first.
  Future<BudgetPeriodPage> periods(String id, {int page = 1}) =>
      _call((dio) async {
        final res = await dio.get<Map<String, dynamic>>(
          '/budgets/$id/periods',
          queryParameters: {'page': page},
        );
        return BudgetPeriodPage.fromJson(res.data);
      });

  /// `listBudgetItems`: everything counted in a period.
  Future<BudgetItemPage> items(
    String id, {
    String? periodId,
    BudgetSource? source,
    int page = 1,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/budgets/$id/items',
      queryParameters: {
        'period_id': ?periodId,
        'source': ?source?.toJson(),
        'page': page,
      },
    );
    return BudgetItemPage.fromJson(res.data);
  });

  /// `closeBudget` (ปิดงบ).
  Future<BudgetDetail> close(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/close');
    return BudgetDetail.fromJson(res.data!);
  });

  /// `archiveBudget`.
  Future<BudgetDetail> archive(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/archive');
    return BudgetDetail.fromJson(res.data!);
  });

  /// `restoreBudget`.
  Future<BudgetDetail> restore(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/restore');
    return BudgetDetail.fromJson(res.data!);
  });

  /// `deleteBudget` (hard).
  Future<void> delete(String id) => _call((dio) async {
    await dio.delete<Map<String, dynamic>>('/budgets/$id');
  });
}
