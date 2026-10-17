import 'package:equatable/equatable.dart';

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

  final String from;
  final String to;

  final double totalIncome;
  final double totalExpense;
  final double net;
  final int transactionCount;

  final String? currency;
  final String? accountId;

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
