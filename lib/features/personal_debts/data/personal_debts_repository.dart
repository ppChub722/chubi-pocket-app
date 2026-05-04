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

  Future<PersonalDebt> create({
    required DebtDirection direction,
    required String counterpartyPersonName,
    required double amount,
    required String currency,
    String? counterpartyContactId,
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
          'note': ?note,
        },
      );
      return PersonalDebt.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PersonalDebt> update(String id, {
    double? amount,
    double? settledAmount,
    String? note,
    DebtStatus? status,
    String? counterpartyPersonName,
    String? counterpartyContactId,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/personal-debts/$id',
        data: <String, dynamic>{
          'amount': ?amount,
          'settled_amount': ?settledAmount,
          'note': ?note,
          'status': ?status?.wire,
          'counterparty_person_name': ?counterpartyPersonName,
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

  /// Settle a debt. Two paths:
  ///   - With `accountId` set + `direct=false` → creates a transaction
  ///     (income for owed_to_me, expense for i_owe) AND bumps settled_amount.
  ///   - With `direct=true` → just bumps settled_amount, no transaction
  ///     (forgiveness, barter, no-cash adjust).
  Future<SettleResult> settle(String id, {
    String? accountId,
    double? amount,
    String? date,
    String? note,
    bool direct = false,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/$id/settle',
        queryParameters: direct ? {'direct': 'true'} : null,
        data: <String, dynamic>{
          'account_id': accountId ?? '00000000-0000-0000-0000-000000000000',
          'amount': ?amount,
          'date': ?date,
          'note': ?note,
        },
      );
      return SettleResult(
        debt: PersonalDebt.fromJson(
            (res.data!['debt'] as Map).cast<String, dynamic>()),
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
