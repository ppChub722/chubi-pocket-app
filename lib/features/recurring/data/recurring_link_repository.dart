import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

/// The present period's occurrence of a [LinkCandidate]
/// (`RecurringOccurrence`): what a transaction would link to.
class LinkOccurrence {
  const LinkOccurrence({
    required this.itemId,
    required this.date,
    required this.daysUntil,
    required this.status,
    this.amount,
  });

  factory LinkOccurrence.fromJson(Map<String, dynamic> json) => LinkOccurrence(
    itemId: json['item_id'] as String,
    date: parseYmd(json['date'] as String?) ?? DateTime.now(),
    daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
    status: (json['status'] as String?) ?? 'upcoming',
    amount: (json['amount'] as num?)?.toDouble(),
  );

  final String itemId;
  final DateTime date;
  final int daysUntil;

  final String status;

  final double? amount;
}

class LinkCandidate {
  const LinkCandidate({
    required this.setting,
    required this.occurrence,
    this.likely = false,
  });

  final Recurring setting;
  final LinkOccurrence occurrence;

  final bool likely;

  bool get isReminder => occurrence.amount == null;
}

class LinkResult {
  const LinkResult({
    required this.transaction,
    required this.amountDiffers,
    required this.ruleAmount,
    required this.transactionAmount,
    this.balances = const {},
  });

  final Transaction? transaction;
  final bool amountDiffers;
  final double? ruleAmount;
  final double transactionAmount;
  final Map<String, double> balances;
}

class RecurringLinkRepository {
  RecurringLinkRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  static RecurringLinkRepository of(BuildContext context) =>
      RecurringLinkRepository(client: context.read<ApiClient>());

  Future<T> _call<T>(Future<T> Function(Dio dio) run) async {
    try {
      return await run(_client.dio);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<LinkResult> link(String itemId, String transactionId) => _call((
    dio,
  ) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring-items/$itemId/link',
      data: {'transaction_id': transactionId},
    );
    final body = res.data!;
    return LinkResult(
      transaction: body['transaction'] is Map<String, dynamic>
          ? Transaction.fromJson(body['transaction'] as Map<String, dynamic>)
          : null,
      amountDiffers: body['amount_differs'] == true,
      ruleAmount: (body['rule_amount'] as num?)?.toDouble(),
      transactionAmount: (body['transaction_amount'] as num?)?.toDouble() ?? 0,
      balances: WalletBalance.mapOf(body['account_balances']),
    );
  });

  Future<RecurringItem> unlink(String itemId) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/recurring-items/$itemId/unlink',
    );
    return RecurringItem.fromJson(res.data!['item'] as Map<String, dynamic>);
  });

  Future<void> updateAmount(String recurringId, double amount) =>
      _call((dio) async {
        await dio.put<Map<String, dynamic>>(
          '/recurring/$recurringId',
          data: {'amount': amount, 'scope': 'upcoming'},
        );
      });
}
