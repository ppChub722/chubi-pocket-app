import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/debt_ledger.dart';

class PersonalDebtsRepository {
  PersonalDebtsRepository({required ApiClient client}) : _client = client;
  final ApiClient _client;

  Future<DebtPersonDetail> person(
    String key, {
    int perPage = 30,
    DebtCycle cycle = DebtCycle.current,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}',
        queryParameters: <String, dynamic>{
          'per_page': perPage.toString(),
          'cycle': cycle.wire,
        },
      );
      return DebtPersonDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtEntriesPage> entries(
    String key, {
    DebtEntryQuery query = const DebtEntryQuery(),
    int page = 1,
    int perPage = 30,
    DebtCycle? cycle,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/entries',
        queryParameters: <String, dynamic>{
          ...query.toQuery(),
          'cycle': ?cycle?.wire,
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );
      return DebtEntriesPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtEntryWriteResult> createEntry(
    String key, {
    required DebtEntryDirection direction,
    required double amount,
    DateTime? date,
    String? accountId,
    bool? createTransaction,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
    String? billId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/entries',
        data: <String, dynamic>{
          'direction': direction.wire,
          'amount': amount,
          if (date != null) 'date': debtDateWire(date),
          'account_id': ?accountId,
          'create_transaction': ?createTransaction,
          'description': ?description,
          'note': ?note,
          if ((accountId != null || createTransaction == true) &&
              tagIds != null)
            'tag_ids': tagIds,
          if (markPaidIds != null && markPaidIds.isNotEmpty)
            'mark_paid_ids': markPaidIds,
          'person_name': ?personName,
          // The event resolve sheet's "as debt" (0.4.0-3 B3): the bill it
          // settles a share of; the debt keeps it as its source.
          'bill_id': ?billId,
        },
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /personal-debts/people/{key}/repayments` (createDebtRepayment): a
  /// repayment = ONE transaction tied to the person (expense "Debt Paid" /
  /// income "Debt Received"), not a debt row (owner 2026-10-21). The BE takes
  /// the wallet as optional; quick create always sends one.
  Future<DebtRepaymentResult> createRepayment(
    String key, {
    required DebtRepaymentKind kind,
    required double amount,
    required String accountId,
    DateTime? date,
    String? description,
    String? note,
    List<String>? tagIds,
    List<String>? markPaidIds,
    String? personName,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/people/${Uri.encodeComponent(key)}/repayments',
        data: <String, dynamic>{
          'kind': kind.wire,
          'amount': amount,
          'account_id': accountId,
          if (date != null) 'date': debtDateWire(date),
          'description': ?description,
          'note': ?note,
          if (tagIds != null && tagIds.isNotEmpty) 'tag_ids': tagIds,
          if (markPaidIds != null && markPaidIds.isNotEmpty)
            'mark_paid_ids': markPaidIds,
          'person_name': ?personName,
        },
      );
      return DebtRepaymentResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The quick-create debt result box (0.4.0-3): the same POST with
  /// `?preview=true`; nothing is saved. Record = [direction] (+ a wallet when
  /// [createTransaction]); settle = [kind].
  Future<DebtPreview> preview(
    String key, {
    DebtEntryDirection? direction,
    DebtRepaymentKind? kind,
    required double amount,
    String? accountId,
    bool? createTransaction,
    String? personName,
  }) async {
    assert((direction == null) != (kind == null), 'record or settle');
    try {
      final person = Uri.encodeComponent(key);
      final res = await _client.dio.post<Map<String, dynamic>>(
        kind == null
            ? '/personal-debts/people/$person/entries'
            : '/personal-debts/people/$person/repayments',
        queryParameters: const {'preview': 'true'},
        data: <String, dynamic>{
          'direction': ?direction?.wire,
          'kind': ?kind?.wire,
          'amount': amount,
          'account_id': ?accountId,
          'create_transaction': ?createTransaction,
          'person_name': ?personName,
        },
      );
      return DebtPreview.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtEntryDetail> getEntry(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtEntryWriteResult> updateEntry(
    String id,
    DebtEntryUpdate update,
  ) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/personal-debts/$id',
        data: update.toJson(),
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The "จ่ายแล้ว" label only (it never changes a number).
  Future<DebtEntryWriteResult> setPaid(String id, bool paid) =>
      updateEntry(id, DebtEntryUpdate(paid: paid));

  Future<DebtEntryDeleteResult> deleteEntry(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/personal-debts/$id',
      );
      return DebtEntryDeleteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtEntryWriteResult> acceptSplit(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/split-requests/$notificationId/accept',
      );
      return DebtEntryWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<DebtSplitChangeResult> applySplit(String notificationId) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/personal-debts/split-changes/$notificationId/apply',
      );
      return DebtSplitChangeResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class DebtEntryUpdate {
  const DebtEntryUpdate({
    this.direction,
    this.amount,
    this.date,
    this.accountId,
    this.clearAccount = false,
    this.createTransaction,
    this.description,
    this.note,
    this.paid,
    this.tagIds,
    this.key,
    this.personName,
  }) : assert(
         !clearAccount || accountId == null,
         'clearAccount and accountId together',
       );

  final DebtEntryDirection? direction;
  final double? amount;
  final DateTime? date;
  final String? accountId;
  final bool clearAccount;

  final bool? createTransaction;
  final String? description;
  final String? note;
  final bool? paid;
  final List<String>? tagIds;

  final String? key;
  final String? personName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'direction': ?direction?.wire,
    'amount': ?amount,
    if (date != null) 'date': debtDateWire(date!),
    if (clearAccount) 'account_id': null else 'account_id': ?accountId,
    'create_transaction': ?createTransaction,
    'description': ?description,
    'note': ?note,
    'paid': ?paid,
    'tag_ids': ?tagIds,
    'key': ?key,
    'person_name': ?personName,
  };
}
