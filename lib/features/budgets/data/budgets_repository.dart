import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';
import '../domain/budget_period.dart';

class BudgetsRepository {
  BudgetsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static BudgetsRepository of(BuildContext context) =>
      context.read<BudgetsRepository>();

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BudgetList> list({
    BudgetFilter filter = BudgetFilter.active,
    BudgetSort sort = BudgetSort.risk,
    BudgetHealth health = BudgetHealth.all,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/budgets',
      queryParameters: {
        'status': filter.toJson(),
        'sort': sort.toJson(),
        'health': ?health.toJson(),
      },
    );
    return BudgetList.fromJson(res.data!);
  });

  Future<BudgetDetail> get(
    String id, {
    String? periodId,
    bool deletePreview = false,
  }) => _call((dio) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/budgets/$id',
      queryParameters: {
        'period_id': ?periodId,
        if (deletePreview) 'include': 'delete_preview',
      },
    );
    return BudgetDetail.fromJson(res.data!);
  });

  Future<BudgetDetail> create(BudgetWrite write) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/budgets',
      data: write.toJson(),
    );
    return BudgetDetail.fromJson(res.data!);
  });

  Future<BudgetDetail> update(String id, BudgetWrite write, {String? apply}) =>
      _call((dio) async {
        final res = await dio.put<Map<String, dynamic>>(
          '/budgets/$id',
          data: write.toJson(apply: apply),
        );
        return BudgetDetail.fromJson(res.data!);
      });

  /// Only what changed is sent: [setAmount] (amount null = back to the base)
  /// and / or [setNote].
  Future<BudgetDetail> updatePeriod(
    String id,
    String periodId, {
    required double? amount,
    required String? note,
    bool setAmount = true,
    bool setNote = true,
  }) => _call((dio) async {
    final res = await dio.put<Map<String, dynamic>>(
      '/budgets/$id/periods/$periodId',
      data: {
        if (setAmount) 'amount': amount,
        if (setNote) 'note': note,
      },
    );
    return BudgetDetail.fromJson(res.data!);
  });

  Future<BudgetPeriodPage> periods(String id, {int page = 1}) =>
      _call((dio) async {
        final res = await dio.get<Map<String, dynamic>>(
          '/budgets/$id/periods',
          queryParameters: {'page': page},
        );
        return BudgetPeriodPage.fromJson(res.data);
      });

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

  Future<BudgetDetail> close(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/close');
    return BudgetDetail.fromJson(res.data!);
  });

  Future<BudgetDetail> archive(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/archive');
    return BudgetDetail.fromJson(res.data!);
  });

  Future<BudgetDetail> restore(String id) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>('/budgets/$id/restore');
    return BudgetDetail.fromJson(res.data!);
  });

  Future<void> delete(String id) => _call((dio) async {
    await dio.delete<Map<String, dynamic>>('/budgets/$id');
  });
}
