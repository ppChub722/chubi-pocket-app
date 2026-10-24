import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';
import '../domain/transactions_summary.dart';

class TransactionsPage {
  const TransactionsPage({
    required this.transactions,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    this.totals,
  });

  final List<Transaction> transactions;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  final ListTotals? totals;

  bool get hasMore => page < totalPages;
}

class DailyFlow {
  const DailyFlow({
    required this.date,
    required this.income,
    required this.expense,
  });

  factory DailyFlow.fromJson(Map<String, dynamic> json) => DailyFlow(
    date: json['date'] as String,
    income: (json['income'] as num?)?.toDouble() ?? 0,
    expense: (json['expense'] as num?)?.toDouble() ?? 0,
  );

  final String date;
  final double income;
  final double expense;
}

class ListTotals {
  const ListTotals({
    required this.income,
    required this.expense,
    required this.net,
    this.count = 0,
    this.avgDailySpend,
    this.daily = const [],
  });

  static ListTotals? fromResponse(Map<String, dynamic> res) {
    final base = fromJson(res['totals']);
    if (base == null) return null;
    return ListTotals(
      income: base.income,
      expense: base.expense,
      net: base.net,
      count: base.count,
      avgDailySpend: (res['avg_daily_spend'] as num?)?.toDouble(),
      daily: [
        for (final d in (res['daily'] as List? ?? const []))
          DailyFlow.fromJson((d as Map).cast<String, dynamic>()),
      ],
    );
  }

  static ListTotals? fromJson(Object? json) {
    if (json is! Map) return null;
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    final income = n(json['income']);
    final expense = n(json['expense']);
    return ListTotals(
      income: income,
      expense: expense,
      net: json['net'] is num ? n(json['net']) : income - expense,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final double income;
  final double expense;
  final double net;
  final int count;

  final double? avgDailySpend;

  final List<DailyFlow> daily;
}

class TransactionsRepository {
  TransactionsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<TransactionsPage> list({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    String? from,
    String? to,
    bool noWallet = false,
    String? q,
    List<String> tagIds = const [],
    bool includeChildren = false,
    bool uncategorized = false,
    List<String> accountIds = const [],
    List<String> categoryIds = const [],
    Set<TransactionType> types = const {},
    bool noTags = false,
    double? amountMin,
    double? amountMax,
    int page = 1,
    int perPage = 20,
    String sort = 'date_desc',
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: <String, dynamic>{
          if (accountId != null || accountIds.isNotEmpty)
            'account_id': [?accountId, ...accountIds],
          if (categoryId != null || categoryIds.isNotEmpty)
            'category_id': [?categoryId, ...categoryIds],
          if (type != null || types.isNotEmpty)
            'type': [?type?.toJson(), for (final t in types) t.toJson()],
          'from': ?from,
          'to': ?to,
          if (noWallet) 'no_wallet': 'true',
          if (q != null && q.isNotEmpty) 'q': q,
          if (tagIds.isNotEmpty) 'tag_id': tagIds,
          if (noTags) 'no_tags': 'true',
          'amount_min': ?amountMin?.toString(),
          'amount_max': ?amountMax?.toString(),
          if (includeChildren) 'include_children': 'true',
          if (uncategorized) 'uncategorized': 'true',
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
        totals: ListTotals.fromResponse(res.data!),
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

  Future<Transaction> updateSplits(
    String id,
    List<Map<String, dynamic>> splits,
  ) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/transactions/$id/splits',
        data: {'splits': splits},
      );
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TransactionMutationResult> create({
    required TransactionType type,
    String? accountId,
    required double amount,
    required String date,
    String? categoryId,
    String? description,
    String? note,
    String? transferToAccountId,
    List<String> tagIds = const [],
    List<Map<String, dynamic>>? splits,
    String? sourceProjectTransactionId,
    Map<String, dynamic>? link,
  }) async {
    try {
      final body = <String, dynamic>{
        // ผูกกับ (0.4.0-3 B1): `paid_by` {contact_id | person_name, amount}.
        ...?link,
        'type': type.toJson(),
        'account_id': ?accountId,
        'amount': amount,
        'date': date,
        'category_id': ?categoryId,
        'description': ?description,
        'note': ?note,
        'transfer_to_account_id': ?transferToAccountId,
        if (tagIds.isNotEmpty) 'tag_ids': tagIds,
        if (splits != null && splits.isNotEmpty) 'splits': splits,
        'source_project_transaction_id': ?sourceProjectTransactionId,
      };
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/transactions',
        data: body,
      );
      try {
        return TransactionWriteResult.fromJson(res.data!);
      } catch (e, st) {
        // Saved on the server (2xx) but unreadable here: keep the body in
        // the log (dev hub > Logs) so the cause shows next time.
        final raw = jsonEncode(res.data);
        AppLogger.instance.error(
          'tx.create_unreadable',
          fields: {
            'error': '$e',
            'status': res.statusCode,
            'body': raw.length > 2000 ? '${raw.substring(0, 2000)}…' : raw,
            'stack': '$st',
          },
        );
        throw ApiException.from(e, st);
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// [link] = a ผูกกับ tab switch (B3): `link_mode` + that tab's data,
  /// sent with the field edits in the one PUT.
  Future<TransactionMutationResult> update({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    String? description,
    bool clearDescription = false,
    String? accountId,
    bool clearAccount = false,
    String? transferToAccountId,
    List<String>? tagIds,
    bool? alsoUpdateLink,
    Map<String, dynamic>? link,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        data: _updateBody(
          amount: amount,
          date: date,
          categoryId: categoryId,
          clearCategory: clearCategory,
          note: note,
          clearNote: clearNote,
          description: description,
          clearDescription: clearDescription,
          accountId: accountId,
          clearAccount: clearAccount,
          transferToAccountId: transferToAccountId,
          tagIds: tagIds,
          alsoUpdateLink: alsoUpdateLink,
          link: link,
        ),
      );
      return TransactionWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The same PUT with `?preview=true`: what would move (people, wallets);
  /// nothing is saved. Feeds the ONE confirm of a tab switch.
  Future<TxEditPreview> previewUpdate({
    required String id,
    double? amount,
    String? date,
    String? accountId,
    bool clearAccount = false,
    required Map<String, dynamic> link,
  }) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        queryParameters: const {'preview': 'true'},
        data: _updateBody(
          amount: amount,
          date: date,
          accountId: accountId,
          clearAccount: clearAccount,
          link: link,
        ),
      );
      return TxEditPreview.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// "อัปเดตตามอีเวนต์": my linked tx takes the bill as it is now.
  Future<TransactionMutationResult> applyEvent(String id) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/transactions/$id/apply-event',
      );
      return TransactionWriteResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static Map<String, dynamic> _updateBody({
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    String? description,
    bool clearDescription = false,
    String? accountId,
    bool clearAccount = false,
    String? transferToAccountId,
    List<String>? tagIds,
    bool? alsoUpdateLink,
    Map<String, dynamic>? link,
  }) {
    final body = <String, dynamic>{...?link, 'amount': ?amount, 'date': ?date};
    if (alsoUpdateLink != null) body['also_update_link'] = alsoUpdateLink;
    if (tagIds != null) body['tag_ids'] = tagIds;
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
    if (description != null) {
      body['description'] = description;
    } else if (clearDescription) {
      body['description'] = null;
    }
    if (accountId != null) {
      body['account_id'] = accountId;
    } else if (clearAccount) {
      body['account_id'] = null;
    }
    if (transferToAccountId != null) {
      body['transfer_to_account_id'] = transferToAccountId;
    }
    return body;
  }

  /// [skipOccurrence]: a tx linked to a recurring occurrence also skips it
  /// (else the occurrence becomes due / upcoming again).
  Future<DeleteTransactionResult> delete(
    String id, {
    bool? alsoDeleteLink,
    bool? skipOccurrence,
  }) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/transactions/$id',
        queryParameters: {
          'also_delete_link': ?alsoDeleteLink,
          'skip_occurrence': ?skipOccurrence,
        },
      );
      return DeleteTransactionResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> setTags(String id, List<String> tagIds) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/transactions/$id/tags',
        data: <String, dynamic>{'tag_ids': tagIds},
      );
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TransactionsSummary> summary({
    required String from,
    required String to,
    String? accountId,
    TransactionType? type,
    String? groupBy,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/transactions/summary',
        queryParameters: <String, dynamic>{
          'from': from,
          'to': to,
          'account_id': ?accountId,
          'type': ?type?.toJson(),
          'group_by': ?groupBy,
        },
      );
      return TransactionsSummary.fromGlobalJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<TransactionsSummary> summaryForAccount({
    required String accountId,
    String? from,
    String? to,
  }) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/accounts/$accountId/summary',
        queryParameters: <String, dynamic>{'from': ?from, 'to': ?to},
      );
      return TransactionsSummary.fromAccountJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
