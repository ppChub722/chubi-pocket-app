import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/saving_entry.dart';
import '../domain/saving_goal.dart';
import '../domain/saving_goals_overview.dart';

/// Thin Dio wrapper for the saving goals v2 API. Pure data layer: it turns
/// [DioException] into [ApiException] and parses JSON; state lives in the
/// cubits.
class SavingGoalsRepository {
  SavingGoalsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// The id the detail endpoint uses for the "ยังไม่จัดสรร" bucket.
  static const spareId = 'spare';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /saving-goals?status=` — the whole list page (summary + spare +
  /// goals) in one call.
  Future<SavingGoalsOverview> list({String status = 'active'}) =>
      _guard(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '/saving-goals',
          queryParameters: {'status': status},
        );
        return SavingGoalsOverview.fromJson(res.data!);
      });

  /// `GET /saving-goals/{id}` (or `spare`) — the whole goal page in one call.
  Future<SavingGoalDetail> detail(String id) => _guard(() async {
    final res = await _client.dio.get<Map<String, dynamic>>(
      '/saving-goals/$id',
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// `GET /saving-entries` — one page of a bucket entries (newest first).
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

  /// `POST /saving-goals` — name, target, deadline, icon, description, note.
  Future<SavingGoalDetail> create(SavingGoal draft) => _guard(() async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/saving-goals',
      data: draft.toWriteJson(),
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// `PUT /saving-goals/{id}`.
  Future<SavingGoalDetail> update(SavingGoal goal) => _guard(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/saving-goals/${goal.id}',
      data: goal.toWriteJson(),
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// `DELETE /saving-goals/{id}`.
  Future<void> delete(String id) =>
      _guard(() => _client.dio.delete<void>('/saving-goals/$id'));

  /// `POST /saving-goals/{id}/archive` / `/restore`.
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

  /// `PUT /saving-goals/{id}/auto-save` (or `spare`) — creates / replaces the
  /// auto-saving: [amount] on [day] of each month, from [accountId] or no
  /// wallet. Answers the goal page / the spare page.
  Future<SavingGoalDetail> setAutoSave(
    String id, {
    required double amount,
    required int day,
    String? accountId,
  }) => _guard(() async {
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/saving-goals/$id/auto-save',
      data: {'amount': amount, 'day': day, 'account_id': accountId},
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// `DELETE /saving-goals/{id}/auto-save` (or `spare`) — turns it off.
  Future<SavingGoalDetail> clearAutoSave(String id) => _guard(() async {
    final res = await _client.dio.delete<Map<String, dynamic>>(
      '/saving-goals/$id/auto-save',
    );
    return SavingGoalDetail.fromJson(res.data!);
  });

  /// `POST /saving-goals/{id}/close` —`toWallets` false = into spare, true =
  /// each part back to its own wallet.
  Future<SavingWriteResult> close(String id, {required bool toWallets}) =>
      _guard(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/saving-goals/$id/close',
          data: {'to': toWallets ? 'wallets' : 'spare'},
        );
        return SavingWriteResult.fromJson(res.data!);
      });

  /// `POST /saving-entries` — ONE call per button: save / withdraw / move.
  /// [goalId] null = the spare bucket. [splits] only when the user edited the
  /// automatic wallet split.
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

  /// `PUT /saving-entries/{id}`.
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

  /// `DELETE /saving-entries/{id}`.
  Future<SavingWriteResult> deleteEntry(String id) => _guard(() async {
    final res = await _client.dio.delete<Map<String, dynamic>>(
      '/saving-entries/$id',
    );
    return SavingWriteResult.fromJson(res.data!);
  });
}
