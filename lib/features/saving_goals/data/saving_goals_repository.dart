import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/saving_entry.dart';
import '../domain/saving_goal.dart';
import '../domain/saving_goals_overview.dart';

class SavingGoalsRepository {
  SavingGoalsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static const spareId = 'spare';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SavingGoalsOverview> list({
    String status = 'active',
    String sort = 'created',
  }) => _guard(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/saving-goals',
      queryParameters: {'status': status, 'sort': sort},
    );
    return SavingGoalsOverview.fromJson(res.data!);
  });

  Future<SavingGoalDetail> detail(String id, {bool deletePreview = false}) =>
      _guard(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '/saving-goals/$id',
          queryParameters: {if (deletePreview) 'include': 'delete_preview'},
        );
        return SavingGoalDetail.fromJson(res.data!);
      });

  Future<SavingEntryPage> entries({
    required String bucketId,
    required int page,
  }) => _guard(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/saving-entries',
      queryParameters: {
        if (bucketId == spareId) 'bucket': spareId else 'goal_id': bucketId,
        'page': page,
      },
    );
    return SavingEntryPage.fromJson(res.data!);
  });

  Future<SavingGoalDetail> create(SavingGoal draft) => _guard(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/saving-goals',
      data: draft.toWriteJson(),
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  Future<SavingGoalDetail> update(SavingGoal goal) => _guard(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/saving-goals/${goal.id}',
      data: goal.toWriteJson(),
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// Only the given keys (PUT is partial): the deadline, the เป้าต่อรอบ …
  Future<SavingGoalDetail> patch(String id, Map<String, dynamic> fields) =>
      _guard(() async {
        final res = await _client.dio.put<Map<String, dynamic>>(
          '/saving-goals/$id',
          data: fields,
        );
        return SavingGoalDetail.fromJson(res.data!);
      });

  Future<void> delete(String id) =>
      _guard(() => _client.dio.delete<void>('/saving-goals/$id'));

  Future<SavingGoalDetail> archive(String id) => _guard(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/saving-goals/$id/archive',
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  Future<SavingGoalDetail> restore(String id) => _guard(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/saving-goals/$id/restore',
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  Future<SavingWriteResult> close(String id, {required bool toWallets}) =>
      _guard(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/saving-goals/$id/close',
          data: {'to': toWallets ? 'wallets' : 'spare'},
        );
        return SavingWriteResult.fromJson(res.data!);
      });

  Future<SavingWriteResult> addEntry({
    required SavingEntryKind kind,
    required double amount,
    required String date,
    String? goalId,
    String? walletId,
    String? toGoalId,
    bool toSpare = false,
    List<SavingSplit>? splits,
    String? note,
  }) => _guard(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/saving-entries',
      data: {
        'kind': kind.toJson(),
        'amount': amount,
        'date': date,
        'goal_id': goalId,
        'wallet_id': ?walletId,
        if (kind == SavingEntryKind.move)
          'to_goal_id': toSpare ? null : toGoalId,
        if (splits != null) 'splits': [for (final s in splits) s.toJson()],
        'note': ?note,
      },
    );
    return SavingWriteResult.fromJson(res.data!);
  });

  Future<SavingWriteResult> updateEntry(
    String id, {
    required double amount,
    required String date,
    String? note,
  }) => _guard(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/saving-entries/$id',
      data: {'amount': amount, 'date': date, 'note': note},
    );
    return SavingWriteResult.fromJson(res.data!);
  });

  Future<SavingWriteResult> deleteEntry(String id) => _guard(() async {
    final res = await _client.dio.delete<Map<String, dynamic>>(
      '/saving-entries/$id',
    );
    return SavingWriteResult.fromJson(res.data!);
  });
}
