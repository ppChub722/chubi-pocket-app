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
    this.groups = const [],
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

  /// `group_by=…` buckets (global summary only).
  final List<SummaryGroup> groups;

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
      groups: [
        for (final g in (json['groups'] as List?) ?? const [])
          SummaryGroup.fromJson(g as Map<String, dynamic>),
      ],
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
        groups,
      ];
}

/// One `group_by` bucket. `income` / `expense` are the typed split from
/// contract §2 (null until the BE sends them); [total] is the old mixed sum.
class SummaryGroup extends Equatable {
  const SummaryGroup({
    required this.key,
    required this.name,
    required this.total,
    required this.count,
    this.income,
    this.expense,
  });

  final String key;
  final String name;
  final double total;
  final int count;
  final double? income;
  final double? expense;

  /// Spending in this bucket — the typed figure when present.
  double get spent => expense ?? total;

  factory SummaryGroup.fromJson(Map<String, dynamic> json) => SummaryGroup(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
        income: (json['income'] as num?)?.toDouble(),
        expense: (json['expense'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [key, name, total, count, income, expense];
}
