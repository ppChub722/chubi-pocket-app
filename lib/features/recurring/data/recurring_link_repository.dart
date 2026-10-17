import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurrence_rule.dart';
import '../domain/recurring.dart';

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

  /// upcoming | pending | not_created.
  final String status;

  /// Null = not known yet (a เตือนจ่าย waiting for its amount).
  final double? amount;
}

/// One row of `GET /recurring?for_type=`: an ACTIVE setting a transaction of
/// that type can link to, as the BE ranked it. [setting] carries the name,
/// icon, rule and category (the recurring model, read as is).
class LinkCandidate {
  const LinkCandidate({required this.setting, required this.occurrence});

  final Recurring setting;
  final LinkOccurrence occurrence;

  /// A เตือนจ่าย still waiting for an amount.
  bool get isReminder => occurrence.amount == null;
}

/// `POST /recurring-items/:id/link` — the answer's amount question.
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

/// The link picker's calls (openapi tag Recurring): the candidates of a
/// transaction type, the link itself and the "update the amount" answer.
/// A separate class so the recurring pages' repository stays untouched.
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

  /// `listRecurring?for_type=` — ONE call, in the BE's order. Settings with
  /// no occurrence now (`current_occurrence` null) can't take a link and are
  /// left out.
  Future<List<LinkCandidate>> candidates(TransactionType type) =>
      _call((dio) async {
        final res = await dio.get<Map<String, dynamic>>(
          '/recurring',
          queryParameters: {'for_type': type.toJson(), 'per_page': 100},
        );
        return [
          for (final e in (res.data!['data'] as List?) ?? const [])
            if ((e as Map<String, dynamic>)['current_occurrence'] is Map)
              LinkCandidate(
                setting: Recurring.fromJson(e),
                occurrence: LinkOccurrence.fromJson(
                  e['current_occurrence'] as Map<String, dynamic>,
                ),
              ),
        ];
      });

  /// `linkRecurringItem`: the transaction becomes the occurrence's saved
  /// record. 409 ITEM_ALREADY_LINKED / 400 (type differs) → [ApiException].
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

  /// "อัปเดต": `PUT /recurring/:id {amount}` (scope upcoming) — the one
  /// call, no separate amount route.
  Future<void> updateAmount(String recurringId, double amount) =>
      _call((dio) async {
        await dio.put<Map<String, dynamic>>(
          '/recurring/$recurringId',
          data: {'amount': amount, 'scope': 'upcoming'},
        );
      });
}
