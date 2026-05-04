import 'package:equatable/equatable.dart';

/// Aggregates returned by `GET /v1/accounts/:id/summary` and
/// `GET /v1/transactions/summary`. Spec §03/§2.7 + §04/§3.6.
///
/// Transfers are excluded from the per-user `total_income` /
/// `total_expense` aggregates (spec §4.13) — they're money movement,
/// not earning or spending. The per-account variant DOES count
/// transfers (spec §03/§2.7) since they affect the account's balance.
class TransactionsSummary extends Equatable {
  const TransactionsSummary({
    required this.from,
    required this.to,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.transactionCount,
    this.currency,
    this.accountId,
  });

  /// Range bounds, `YYYY-MM-DD`. Echoed back from the request.
  final String from;
  final String to;

  final double totalIncome;
  final double totalExpense;
  final double net;
  final int transactionCount;

  /// Set on per-account summaries (`/accounts/:id/summary`); null on
  /// the global summary.
  final String? currency;
  final String? accountId;

  factory TransactionsSummary.fromAccountJson(Map<String, dynamic> json) {
    return TransactionsSummary(
      from: json['from'] as String,
      to: json['to'] as String,
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
      transactionCount: (json['transaction_count'] as int?) ?? 0,
      currency: json['currency'] as String?,
      accountId: json['account_id'] as String?,
    );
  }

  factory TransactionsSummary.fromGlobalJson(Map<String, dynamic> json) {
    return TransactionsSummary(
      from: json['from'] as String,
      to: json['to'] as String,
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
      transactionCount: (json['transaction_count'] as int?) ?? 0,
      currency: json['currency'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        from,
        to,
        totalIncome,
        totalExpense,
        net,
        transactionCount,
        currency,
        accountId,
      ];
}
