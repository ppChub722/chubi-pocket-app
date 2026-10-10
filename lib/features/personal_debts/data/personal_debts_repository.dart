import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/personal_debt.dart';

class DebtsPage {
  const DebtsPage({
    required this.debts,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });
  final List<PersonalDebt> debts;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;
}

class SettleResult {
  const SettleResult({required this.debt});
  final PersonalDebt debt;
}

class PersonalDebtsRepository {
  PersonalDebtsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  Future<DebtsPage> list({
    DebtDirection? direction,
    String? status,
    String? counterpartyContactId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts',
        queryParameters: <String, dynamic>{
          'direction': ?direction?.wire,
          'status': ?status,
          'counterparty_contact_id': ?counterpartyContactId,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      final pag = res.data!['pagination'] as Map<String, dynamic>;
      // The view shape is identical to PersonalDebt + outstanding; ignore the
      // server-computed outstanding (FE recomputes from amount/settled).
      return DebtsPage(
        debts: data.map(PersonalDebt.fromJson).toList(),
        page: pag['page'] as int,
        perPage: pag['per_page'] as int,
        total: pag['total'] as int,
        totalPages: pag['total_pages'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PersonalDebt> get(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/personal-debts/split-requests/:notification_id/accept` —
  /// "add to my debts" on a split someone shared with me (contract §5).
  Future<PersonalDebt> acceptSplitRequest(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/split-requests/$notificationId/accept',
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PersonalDebt> create({
    required DebtDirection direction,
    required String counterpartyPersonName,
    required double amount,
    required String currency,
    String? counterpartyContactId,
    String? description,
    String? note,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts',
        data: <String, dynamic>{
          'direction': direction.wire,
          'counterparty_person_name': counterpartyPersonName,
          'amount': amount,
          'currency': currency,
          'counterparty_contact_id': ?counterpartyContactId,
          'description': ?description,
          'note': ?note,
        },
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Every debt (all pages; the API caps a page at 100).
  Future<List<PersonalDebt>> listAll({String status = 'all'}) async {
    final out = <PersonalDebt>[];
    var page = 1;
    while (true) {
      final p = await list(status: status, page: page, perPage: 100);
      out.addAll(p.debts);
      if (!p.hasMore) return out;
      page++;
    }
  }

  /// [clearContact] sends an explicit `counterparty_contact_id: null`
  /// (switching to a typed name) — contract §7. [description] / [note]:
  /// null = unchanged, `''` = clear (migration 51).
  Future<PersonalDebt> update(
    String id, {
    double? amount,
    double? settledAmount,
    String? description,
    String? note,
    DebtStatus? status,
    String? counterpartyPersonName,
    String? counterpartyContactId,
    bool clearContact = false,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/personal-debts/$id',
        data: <String, dynamic>{
          'amount': ?amount,
          'settled_amount': ?settledAmount,
          'description': ?description,
          'note': ?note,
          'status': ?status?.wire,
          'counterparty_person_name': ?counterpartyPersonName,
          if (clearContact)
            'counterparty_contact_id': null
          else
            'counterparty_contact_id': ?counterpartyContactId,
        },
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<dynamic>('/personal-debts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PersonalDebt> cancel(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/$id/cancel',
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Settle a debt: always records a transaction (income for owed_to_me,
  /// expense for i_owe) — into [accountId], or a floating (no-wallet) row
  /// when it's null — and bumps settled_amount. Write-offs use cancel.
  /// No [description] → the server copies the debt's; no [note] → empty.
  Future<SettleResult> settle(
    String id, {
    String? accountId,
    double? amount,
    String? date,
    String? description,
    String? note,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/$id/settle',
        data: <String, dynamic>{
          // None = a floating (no-wallet) transaction (contract §7).
          'account_id': ?accountId,
          'amount': ?amount,
          'date': ?date,
          'description': ?description,
          'note': ?note,
        },
      );
      return SettleResult(
        debt: PersonalDebt.fromJson(
          (res.data!['debt'] as Map).cast<String, dynamic>(),
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PeopleResponse> people() async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people',
      );
      return PeopleResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
