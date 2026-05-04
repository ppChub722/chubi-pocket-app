import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/account.dart';

/// Thin Dio wrapper for `/v1/accounts` (spec §03/§2.1–§2.7).
///
/// Pure data layer — translates [DioException] into [ApiException] and
/// parses JSON into [Account]. State + caching live in [AccountsCubit].
class AccountsRepository {
  AccountsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/accounts`. Default returns active accounts; pass
  /// `status: 'all'` to include archived/closed for the user's history view.
  Future<List<Account>> list({String status = 'active', String? type}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts',
        queryParameters: <String, dynamic>{
          'status': status,
          'type': ?type,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Account.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/accounts`. Server creates the row + (when [Account.balance]
  /// is non-zero) an Opening Balance transaction in the same DB tx, so the
  /// returned `balance` already reflects the opening transaction.
  Future<Account> create(Account draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts',
        data: draft.toCreateJson(),
      );
      return Account.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/accounts/:id`. Sends the full editable surface; server
  /// distinguishes "clear" (explicit null) from "leave alone" (field
  /// missing) for `description` and `note` per [Account.toUpdateJson].
  Future<Account> update(Account account) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/accounts/${account.id}',
        data: account.toUpdateJson(),
      );
      return Account.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/accounts/:id` — soft delete (status → archived) per
  /// spec §3.10. Hard delete is not offered.
  Future<void> archive(String id) async {
    try {
      await _client.dio.delete<Map<String, dynamic>>('/accounts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/accounts/:id/adjust-balance` — spec §2.5. Server creates
  /// an Adjustment transaction whose delta brings the account's cached
  /// balance to [newBalance]. Returns both the updated account and the
  /// id of the synthetic Adjustment transaction so the UI can offer a
  /// "View" action that navigates to it.
  Future<AdjustBalanceOutcome> adjustBalance({
    required String id,
    required double newBalance,
    String? note,
    String? date,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/adjust-balance',
        data: <String, dynamic>{
          'new_balance': newBalance,
          'note': ?note,
          'date': ?date,
        },
      );
      return AdjustBalanceOutcome(
        account: Account.fromJson(res.data!['account'] as Map<String, dynamic>),
        adjustmentTransactionId:
            res.data!['adjustment_transaction_id'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Result of [AccountsRepository.adjustBalance]. Spec §03/§2.5: the
/// server creates a synthetic Adjustment transaction whose delta
/// brings the cached balance to the requested value — both the
/// updated account and that transaction's id come back.
class AdjustBalanceOutcome {
  const AdjustBalanceOutcome({
    required this.account,
    required this.adjustmentTransactionId,
  });
  final Account account;
  final String adjustmentTransactionId;
}
