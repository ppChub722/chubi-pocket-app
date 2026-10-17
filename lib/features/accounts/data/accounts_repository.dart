import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/domain/notification.dart';
import '../domain/account.dart';
import '../domain/payment_provider.dart';
import '../domain/wallet_member.dart';

/// Thin Dio wrapper around `/v1/accounts` (API v2) plus the shared-wallet
/// member surface (spec §14).
///
/// Pure data layer — translates [DioException] into [ApiException] and
/// parses JSON into the wallet models. State + caching live in
/// [AccountsCubit]. Every write returns its final state (the wallet, the
/// members list or the touched balances) so callers patch, never refetch.
class AccountsRepository {
  AccountsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Cached `GET /v1/payment-providers` — the list only changes with a
  /// BE migration, so one fetch per app run.
  Future<List<PaymentProvider>>? _providers;

  /// `GET /v1/payment-providers` — banks (and later e-wallets / card
  /// issuers) for the wallet page's bank picker. A failed fetch isn't
  /// cached, so the next call tries again.
  Future<List<PaymentProvider>> paymentProviders() {
    return _providers ??= () async {
      try {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '/payment-providers',
        );
        final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
        return data.map(PaymentProvider.fromJson).toList();
      } on DioException catch (e) {
        _providers = null;
        throw ApiException.fromDioException(e);
      }
    }();
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/accounts` — the wallets, `totals` and `archived_count` in one
  /// call. Default returns active wallets; `status: 'archived'` the archived
  /// ones.
  Future<AccountList> list({String status = 'active', String? type}) {
    return _guard(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts',
        queryParameters: <String, dynamic>{'status': status, 'type': ?type},
      );
      return AccountList.fromJson(res.data!);
    });
  }

  /// `GET /v1/accounts/:id?include=summary,members` — one call renders the
  /// wallet page; works for any status, archived included.
  Future<AccountDetail> getDetail(String id) {
    return _guard(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$id',
        queryParameters: const {'include': 'summary,members'},
      );
      return AccountDetail.fromJson(res.data!);
    });
  }

  /// `PATCH /v1/accounts/reorder` — [ids] in the caller's new order. The
  /// order is per member: it never moves a shared wallet for anyone else.
  /// Returns the list in the new order.
  Future<AccountList> reorder(List<String> ids) {
    return _guard(() async {
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/accounts/reorder',
        data: {
          'items': [
            for (var i = 0; i < ids.length; i++)
              {'id': ids[i], 'sort_order': i},
          ],
        },
      );
      return AccountList.fromJson(res.data!);
    });
  }

  /// `POST /v1/accounts`. Server creates the row + (when [Account.balance]
  /// is non-zero) an Opening Balance transaction in the same DB tx, so the
  /// returned `balance` already reflects the opening transaction. No
  /// `currency` is sent: the wallet takes the user's own.
  Future<Account> create(Account draft) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts',
        data: draft.toCreateJson(),
      );
      return Account.fromJson(res.data!);
    });
  }

  /// `PUT /v1/accounts/:id` (owner). Sends the editable surface (no
  /// currency / status / balance); explicit nulls clear `description` and
  /// `note` per [Account.toUpdateJson].
  Future<Account> update(Account account, {double? currentBalance}) {
    return _guard(() async {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/accounts/${account.id}',
        data: account.toUpdateJson(currentBalance: currentBalance),
      );
      return Account.fromJson(res.data!);
    });
  }

  /// `DELETE /v1/accounts/:id` — soft delete (status → archived); returns
  /// the archived wallet. `409 ACCOUNT_HAS_MEMBERS` while others are in it.
  Future<Account> archive(String id) {
    return _guard(() async {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/accounts/$id',
      );
      return Account.fromJson(res.data!);
    });
  }

  /// `POST /v1/accounts/:id/restore` — un-archive (owner); returns the
  /// wallet, active again.
  Future<Account> restore(String id) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/restore',
      );
      return Account.fromJson(res.data!);
    });
  }

  /// `POST /v1/accounts/:id/adjust-balance` — any member. The server books
  /// an Adjustment transaction whose delta brings the balance to
  /// [newBalance]; returns the wallet, that row's id and the touched
  /// balances. `400 NO_OP` when the balance already equals [newBalance].
  Future<AdjustBalanceResult> adjustBalance({
    required String id,
    required double newBalance,
    String? description,
    String? note,
    String? date,
  }) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/adjust-balance',
        data: <String, dynamic>{
          'new_balance': newBalance,
          'description': ?description,
          'note': ?note,
          'date': ?date,
        },
      );
      return AdjustBalanceResult.fromJson(res.data!);
    });
  }

  /// `POST /v1/accounts/:id/identifiers` — remember one slip number
  /// (owner); an identical one is not added twice. Returns the wallet.
  Future<Account> addIdentifier(String id, Map<String, dynamic> identifier) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/identifiers',
        data: identifier,
      );
      return Account.fromJson(res.data!);
    });
  }

  // ─── Shared wallets (spec §14 / API §14) ────────────────────────────

  /// `POST /v1/accounts/:id/members` (owner) — the invitee gets the
  /// account_invite notification. Body: exactly one of `{"contact_id"}` (one
  /// of my contacts linked to an app user) or `{"email"}`. Returns the
  /// wallet + the whole members list.
  /// Errors: `400 VALIDATION_ERROR`, `404 CONTACT_NOT_FOUND` /
  /// `USER_NOT_FOUND`, `409 CONTACT_ARCHIVED` / `USER_ALREADY_MEMBER`,
  /// `422 CONTACT_NOT_LINKED`, `403 NOT_OWNER`. The conversion warning is
  /// gated client-side — callers must confirm before the FIRST invite on a
  /// personal wallet.
  Future<MembersResult> inviteMember({
    required String accountId,
    String? contactId,
    String? email,
  }) {
    assert(
      (contactId == null) != (email == null),
      'send exactly one of contactId / email',
    );
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$accountId/members',
        data: <String, dynamic>{'contact_id': ?contactId, 'email': ?email},
      );
      return MembersResult.fromJson(res.data!);
    });
  }

  /// `DELETE /v1/accounts/:id/members/:member_id` — leave (self), remove
  /// someone or cancel an invite (owner). Returns the wallet + the members
  /// list; leaving yourself returns `{account: null, members: []}`.
  /// `400 OWNER_MUST_TRANSFER` (the owner cannot leave), `403 NOT_OWNER`.
  Future<MembersResult> removeMember({
    required String accountId,
    required String memberId,
  }) {
    return _guard(() async {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/accounts/$accountId/members/$memberId',
      );
      return MembersResult.fromJson(res.data!);
    });
  }

  /// `POST /v1/accounts/:id/transfer-ownership` — owner only, target must
  /// be an active member. Returns the wallet + the members list.
  Future<MembersResult> transferOwnership({
    required String accountId,
    required String newOwnerUserId,
  }) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$accountId/transfer-ownership',
        data: <String, dynamic>{'new_owner_user_id': newOwnerUserId},
      );
      return MembersResult.fromJson(res.data!);
    });
  }

  /// `PUT /v1/accounts/:id/report-scope` — the caller's own membership
  /// only. Returns the wallet. `403 SCOPE_NOT_ALLOWED` when the owner
  /// limits what members can choose.
  Future<Account> setReportScope({
    required String accountId,
    required WalletReportScope scope,
  }) {
    return _guard(() async {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/accounts/$accountId/report-scope',
        data: <String, dynamic>{'report_scope': scope.wire},
      );
      return Account.fromJson(res.data!);
    });
  }

  /// Accept a wallet invite from its notification. Returns the wallet that
  /// was joined plus the notification / badges / inbox summary answer.
  Future<AcceptedInvite> acceptInvite(String notificationId) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/invites/$notificationId/accept',
      );
      return AcceptedInvite(
        account: Account.fromJson(res.data!['account'] as Map<String, dynamic>),
        answer: NotificationActionResult.fromJson(res.data!),
      );
    });
  }

  /// Reject a wallet invite from its notification (silent to the sender).
  Future<NotificationActionResult> rejectInvite(String notificationId) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/invites/$notificationId/reject',
      );
      return NotificationActionResult.fromJson(res.data!);
    });
  }
}

/// `POST /accounts/invites/:id/accept` answer: the wallet joined and the
/// inbox answer (row, badges, summary).
class AcceptedInvite {
  const AcceptedInvite({required this.account, required this.answer});
  final Account account;
  final NotificationActionResult answer;
}
