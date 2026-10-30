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
    this.ruleId,
    this.slot,
    this.linkedTxId,
  });

  factory LinkOccurrence.fromJson(Map<String, dynamic> json) => LinkOccurrence(
    itemId:
        json['item_id'] as String? ?? 'slot:${json['rule_id']}:${json['slot']}',
    date: parseYmd(json['date'] as String?) ?? DateTime.now(),
    daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
    status: (json['status'] as String?) ?? 'upcoming',
    amount: (json['amount'] as num?)?.toDouble(),
    ruleId: json['rule_id'] as String?,
    slot: json['slot'] as String?,
  );

  factory LinkOccurrence.ofItem(RecurringItem i) => LinkOccurrence(
    itemId: i.id,
    date: i.date,
    daysUntil: i.daysUntil,
    status: i.state.name,
    amount: i.amount,
    ruleId: i.ruleId,
    slot: i.slot,
    linkedTxId: i.transaction?.id,
  );

  final String itemId;
  final DateTime date;
  final int daysUntil;

  final String status;

  final double? amount;

  /// Set from the occurrence picker: linking goes by rule + slot.
  final String? ruleId;
  final String? slot;

  /// The tx this occurrence is already linked to.
  final String? linkedTxId;

  bool get bySlot => ruleId != null && slot != null;
}

class LinkCandidate {
  const LinkCandidate({
    required this.setting,
    required this.occurrence,
    this.likely = false,
    this.replace = false,
  });

  final Recurring setting;
  final LinkOccurrence occurrence;

  final bool likely;

  /// The owner already said "สลับ": linking replaces the occurrence's tx.
  final bool replace;

  bool get isReminder => occurrence.amount == null;
}

class LinkResult {
  const LinkResult({
    required this.transaction,
    required this.amountDiffers,
    required this.ruleAmount,
    required this.transactionAmount,
    this.balances = const {},
    this.item,
  });

  final Transaction? transaction;

  /// The linked occurrence as it is now.
  final RecurringItem? item;
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
    } catch (e, st) {
      throw ApiException.from(e, st);
    }
  }

  Future<LinkResult> _link(
    String path,
    String transactionId,
    bool replace,
  ) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(
      path,
      data: {'transaction_id': transactionId, if (replace) 'replace': true},
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
      item: body['item'] is Map<String, dynamic>
          ? RecurringItem.fromJson(body['item'] as Map<String, dynamic>)
          : null,
    );
  });

  /// [replace]: the occurrence's tx (or this tx's other occurrence) lets go
  /// in the same call; without it a taken side answers 409.
  Future<LinkResult> link(
    String itemId,
    String transactionId, {
    bool replace = false,
  }) => _link('/recurring-items/$itemId/link', transactionId, replace);

  Future<LinkResult> linkOccurrence(
    String ruleId,
    String slot,
    String transactionId, {
    bool replace = false,
  }) => _link(
    '/recurring/$ruleId/occurrences/$slot/link',
    transactionId,
    replace,
  );

  Future<RecurringItem?> _unlink(String path) => _call((dio) async {
    final res = await dio.post<Map<String, dynamic>>(path);
    final item = res.data?['item'];
    return item is Map<String, dynamic> ? RecurringItem.fromJson(item) : null;
  });

  Future<RecurringItem?> unlink(String itemId) =>
      _unlink('/recurring-items/$itemId/unlink');

  /// The occurrence goes back to ค้าง / ยังไม่ถึง; the tx stays.
  Future<RecurringItem?> unlinkOccurrence(String ruleId, String slot) =>
      _unlink('/recurring/$ruleId/occurrences/$slot/unlink');

  Future<void> updateAmount(String recurringId, double amount) =>
      _call((dio) async {
        await dio.put<Map<String, dynamic>>(
          '/recurring/$recurringId',
          data: {'amount': amount, 'scope': 'upcoming'},
        );
      });
}
