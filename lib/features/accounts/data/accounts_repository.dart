import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../notifications/domain/notification.dart';
import '../domain/account.dart';
import '../domain/payment_provider.dart';
import '../domain/wallet_member.dart';

class AccountsRepository {
  AccountsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<PaymentProvider>>? _providers;

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

  Future<AccountList> list({String status = 'active', String? type}) {
    return _guard(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts',
        queryParameters: <String, dynamic>{'status': status, 'type': ?type},
      );
      return AccountList.fromJson(res.data!);
    });
  }

  Future<AccountDetail> getDetail(String id) {
    return _guard(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$id',
        queryParameters: const {'include': 'summary,members'},
      );
      return AccountDetail.fromJson(res.data!);
    });
  }

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

  Future<Account> create(Account draft) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts',
        data: draft.toCreateJson(),
      );
      return Account.fromJson(res.data!);
    });
  }

  Future<Account> update(Account account, {double? currentBalance}) {
    return _guard(() async {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/accounts/${account.id}',
        data: account.toUpdateJson(currentBalance: currentBalance),
      );
      return Account.fromJson(res.data!);
    });
  }

  Future<Account> archive(String id) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/archive',
      );
      return Account.fromJson(res.data!);
    });
  }

  /// `GET /v1/accounts/:id?include=delete_preview` — what a delete would do
  /// (the confirm dialog).
  Future<AccountDeletePreview?> deletePreview(String id) {
    return _guard(() async {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$id',
        queryParameters: const {'include': 'delete_preview'},
      );
      final p = res.data!['delete_preview'];
      return p is Map<String, dynamic>
          ? AccountDeletePreview.fromJson(p)
          : null;
    });
  }

  Future<AccountDeletePreview> delete(String id) {
    return _guard(() async {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/accounts/$id',
      );
      return AccountDeletePreview.fromJson(
        (res.data!['deleted'] as Map).cast<String, dynamic>(),
      );
    });
  }

  Future<Account> restore(String id) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/restore',
      );
      return Account.fromJson(res.data!);
    });
  }

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

  Future<Account> addIdentifier(String id, Map<String, dynamic> identifier) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/$id/identifiers',
        data: identifier,
      );
      return Account.fromJson(res.data!);
    });
  }

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

  Future<NotificationActionResult> rejectInvite(String notificationId) {
    return _guard(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/accounts/invites/$notificationId/reject',
      );
      return NotificationActionResult.fromJson(res.data!);
    });
  }
}

class AcceptedInvite {
  const AcceptedInvite({required this.account, required this.answer});
  final Account account;
  final NotificationActionResult answer;
}
