import 'package:equatable/equatable.dart';

import 'recurring.dart';

class KindTotals extends Equatable {
  const KindTotals({this.count = 0, this.monthly = 0, this.yearly = 0});

  factory KindTotals.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const KindTotals();
    return KindTotals(
      count: (json['count'] as num?)?.toInt() ?? 0,
      monthly: (json['monthly'] as num?) ?? 0,
      yearly: (json['yearly'] as num?) ?? 0,
    );
  }

  final int count;
  final num monthly;
  final num yearly;

  @override
  List<Object?> get props => [count, monthly, yearly];
}

class RecurringSummary extends Equatable {
  const RecurringSummary({
    this.monthPay = 0,
    this.monthReceive = 0,
    this.due30dTotal = 0,
    this.awaitingAmountCount = 0,
    this.byKind = const {},
    this.nextName,
    this.nextDate,
    this.nextAmount,
  });

  static RecurringSummary? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final next = json['next'];
    final kinds = json['by_kind'];
    return RecurringSummary(
      monthPay: (json['month_pay'] as num?) ?? 0,
      monthReceive: (json['month_receive'] as num?) ?? 0,
      due30dTotal: (json['due_30d_total'] as num?) ?? 0,
      awaitingAmountCount:
          (json['awaiting_amount_count'] as num?)?.toInt() ?? 0,
      byKind: {
        for (final k in RecurringKind.values)
          k: KindTotals.fromJson(
            kinds is Map<String, dynamic> ? kinds[k.name] : null,
          ),
      },
      nextName: next is Map<String, dynamic> ? next['name'] as String? : null,
      nextDate: next is Map<String, dynamic>
          ? DateTime.tryParse((next['date'] as String?) ?? '')
          : null,
      nextAmount: next is Map<String, dynamic>
          ? (next['amount'] as num?)?.toDouble()
          : null,
    );
  }

  final num monthPay;
  final num monthReceive;
  final num due30dTotal;
  final int awaitingAmountCount;
  final Map<RecurringKind, KindTotals> byKind;
  final String? nextName;
  final DateTime? nextDate;
  final double? nextAmount;

  @override
  List<Object?> get props => [
    monthPay,
    monthReceive,
    due30dTotal,
    awaitingAmountCount,
    byKind,
    nextName,
    nextDate,
    nextAmount,
  ];
}
