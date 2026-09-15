import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/account.dart';
import '../domain/wallet_member.dart';

/// Thin Dio wrapper around `/v1/accounts` (spec §03/§2.1–§2.7) plus the
/// shared-wallet member surface (spec §14, API §14 pinned contracts).
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

  // ─── Shared wallets (spec §14 / API §14) ────────────────────────────

  /// Full membership list for the wallet, including pending invites and
  /// past members (`left_at` set — history is append-only). Mirrors the
  /// projects `GET /members` pattern; the pinned §14 contract only fixes
  /// the active-member embed on `GET /v1/accounts`, so this endpoint's
  /// row shape follows `account_members` (§14/3.1).
  Future<List<WalletMember>> listMembers(String accountId) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$accountId/members',
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(WalletMember.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/accounts/:id/members` body `{"email": "..."}` → 201
  /// pending member (notification-pattern invite, same as projects).
  /// Errors: `404 USER_NOT_FOUND`, `409 USER_ALREADY_MEMBER`,
  /// `403 NOT_MEMBER`. The conversion warning is gated client-side —
  /// callers must confirm before the FIRST invite on a personal wallet.
  Future<WalletMember> inviteMember({
    required String accountId,
    required String email,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$accountId/members',
        data: <String, dynamic>{'email': email},
      );
      return WalletMember.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/accounts/:id/members/:member_id` — leave (self) or
  /// remove (owner). Sets `left_at`; rows untouched, the ex-member's
  /// rows lock read-only for them. Owner leaving with other members
  /// present → `409 OWNER_MUST_TRANSFER`.
  Future<void> removeMember({
    required String accountId,
    required String memberId,
  }) async {
    try {
      await _client.dio.delete<dynamic>(
        '/accounts/$accountId/members/$memberId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/accounts/:id/transfer-ownership` — owner only, target
  /// must be an active member. Required before an owner leaves a
  /// still-shared wallet.
  Future<void> transferOwnership({
    required String accountId,
    required String newOwnerUserId,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/accounts/$accountId/transfer-ownership',
        data: <String, dynamic>{'new_owner_user_id': newOwnerUserId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/accounts/:id/report-scope` — the caller's own membership
  /// only. Ex-members may set `none|own` (`400 SCOPE_NOT_ALLOWED` for
  /// `all`).
  Future<void> setReportScope({
    required String accountId,
    required WalletReportScope scope,
  }) async {
    try {
      await _client.dio.put<dynamic>(
        '/accounts/$accountId/report-scope',
        data: <String, dynamic>{'report_scope': scope.wire},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Accept a wallet invite from its notification. Mirrors the project
  /// link-request endpoints (`POST /v1/projects/link-requests/:id/accept`)
  /// per spec §14/8.1 "notification pattern, same as project member
  /// invites".
  Future<void> acceptInvite(String notificationId) async {
    try {
      await _client.dio.post<dynamic>(
        '/accounts/invites/$notificationId/accept',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Reject a wallet invite from its notification (silent to the sender).
  Future<void> rejectInvite(String notificationId) async {
    try {
      await _client.dio.post<dynamic>(
        '/accounts/invites/$notificationId/reject',
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
