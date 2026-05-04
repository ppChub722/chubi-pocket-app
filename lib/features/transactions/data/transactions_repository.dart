import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import '../domain/transactions_summary.dart';

/// Pagination block returned alongside a list response (spec §3.2).
class TransactionsPage {
  const TransactionsPage({
    required this.transactions,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  final List<Transaction> transactions;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// `/v1/transactions/*` endpoints.
class TransactionsRepository {
  TransactionsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// `GET /v1/transactions`. All filters are optional; default sort is
  /// date_desc per spec §3.2. Default `perPage` is 20 (BE default).
  Future<TransactionsPage> list({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
    String sort = 'date_desc',
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: <String, dynamic>{
          'account_id': ?accountId,
          'category_id': ?categoryId,
          'type': ?type?.toJson(),
          'from': ?from,
          'to': ?to,
          'page': page.toString(),
          'per_page': perPage.toString(),
          'sort': sort,
        },
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      final pag = res.data!['pagination'] as Map<String, dynamic>;
      return TransactionsPage(
        transactions: data.map(Transaction.fromJson).toList(),
        page: pag['page'] as int,
        perPage: pag['per_page'] as int,
        total: pag['total'] as int,
        totalPages: pag['total_pages'] as int,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> get(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/transactions/$id',
      );
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/transactions`. Returns either a single [Transaction]
  /// (expense / income) or a [TransferResult] of two rows (transfer)
  /// per spec §3.1 — wrapped in [TransactionMutationResult].
  ///
  /// For transfers, [transferToAccountId] must be set and differ from
  /// [accountId]; both accounts must share the same currency in
  /// Phase 1 (BE rejects with `TRANSFER_CURRENCY_MISMATCH` otherwise).
  Future<TransactionMutationResult> create({
    required TransactionType type,
    required String accountId,
    required double amount,
    required String date,
    String? categoryId,
    String? note,
    String? transferToAccountId,
    List<Map<String, dynamic>>? splits,
    String? sourceProjectTransactionId,
  }) async {
    try {
      final body = <String, dynamic>{
        'type': type.toJson(),
        'account_id': accountId,
        'amount': amount,
        'date': date,
        'category_id': ?categoryId,
        'note': ?note,
        'transfer_to_account_id': ?transferToAccountId,
        if (splits != null && splits.isNotEmpty) 'splits': splits,
        'source_project_transaction_id': ?sourceProjectTransactionId,
      };
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/transactions',
        data: body,
      );
      return TransactionMutationResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/transactions/:id`. Per spec §3.4, editable fields are
  /// `amount`, `date`, `category_id`, `note`. For transfers the BE
  /// cascades the change to the paired row + re-balances both accounts
  /// atomically and returns a [TransferResult] envelope.
  ///
  /// `category_id` and `note` use presence semantics: pass `null` and
  /// set `clearCategory` / `clearNote` to true to send an explicit
  /// `null` (clears the column); leave both args null + flags false to
  /// omit the field (leaves the column unchanged).
  Future<TransactionMutationResult> update({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': ?amount,
        'date': ?date,
      };
      if (categoryId != null) {
        body['category_id'] = categoryId;
      } else if (clearCategory) {
        body['category_id'] = null;
      }
      if (note != null) {
        body['note'] = note;
      } else if (clearNote) {
        body['note'] = null;
      }
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        data: body,
      );
      return TransactionMutationResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/transactions/:id`. For transfers the paired row is
  /// also deleted and both balances reverse (spec §3.5). The endpoint
  /// returns no body of interest beyond status.
  Future<void> delete(String id) async {
    try {
      await _client.dio.delete<Map<String, dynamic>>('/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /v1/transactions/:id/tags` — attaches a list of tag ids
  /// to a transaction. Idempotent (already-attached tags are no-ops
  /// per spec §3.11). Returns the transaction's full tag list as
  /// [EmbeddedTag] so the caller can patch its cache without a
  /// follow-up GET.
  Future<List<EmbeddedTag>> attachTags({
    required String transactionId,
    required List<String> tagIds,
  }) async {
    if (tagIds.isEmpty) return const [];
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/transactions/$transactionId/tags',
        data: <String, dynamic>{'tag_ids': tagIds},
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      // The Tag shape from /v1/tags is a superset of EmbeddedTag —
      // pulling only the fields we care about.
      return data
          .map((j) => EmbeddedTag(
                id: j['id'] as String,
                name: j['name'] as String,
                color: j['color'] as String?,
                icon: j['icon'] as String?,
              ))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /v1/transactions/:id/tags/:tag_id` — detaches one tag.
  /// Idempotent. No useful body returned; caller should patch its
  /// local list.
  Future<void> detachTag({
    required String transactionId,
    required String tagId,
  }) async {
    try {
      await _client.dio.delete<Map<String, dynamic>>(
        '/transactions/$transactionId/tags/$tagId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/transactions/summary`. Global summary across the user's
  /// own book — date range required, optional filters. Summary
  /// respects the `include_in_report` rule the same way per-account
  /// summaries do (spec §03/§2.7 + §05/§4.14c).
  Future<TransactionsSummary> summary({
    required String from,
    required String to,
    String? accountId,
    TransactionType? type,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/transactions/summary',
        queryParameters: <String, dynamic>{
          'from': from,
          'to': to,
          'account_id': ?accountId,
          'type': ?type?.toJson(),
        },
      );
      return TransactionsSummary.fromGlobalJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `GET /v1/accounts/:id/summary`. The accounts module owns this
  /// endpoint (it joins against transactions and resolves the user's
  /// system Transfer IN/OUT categories). Per-account summaries DO
  /// count transfers in their income / expense aggregates per spec
  /// §03/§2.7 — that's intentional, transfers move the balance.
  Future<TransactionsSummary> summaryForAccount({
    required String accountId,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$accountId/summary',
        queryParameters: <String, dynamic>{
          'from': ?from,
          'to': ?to,
        },
      );
      return TransactionsSummary.fromAccountJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
