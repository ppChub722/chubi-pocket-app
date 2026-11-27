import 'package:equatable/equatable.dart';

import 'recurring.dart';

/// The BE totals by its round kinds (subscription / installment / reminder /
/// income / saving / debt) folded into the 5 item types (0.4.3).
KindTotals _kindTotals(Map<String, dynamic> kinds, RecurringKind k) {
  final keys = switch (k) {
    RecurringKind.expense => const ['subscription', 'installment', 'reminder'],
    _ => [k.name],
  };
  var count = 0;
  num monthly = 0, yearly = 0;
  for (final key in keys) {
    final t = KindTotals.fromJson(kinds[key]);
    count += t.count;
    monthly += t.monthly;
    yearly += t.yearly;
  }
  return KindTotals(count: count, monthly: monthly, yearly: yearly);
}

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
    this.month = const MonthHero(),
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
          k: _kindTotals(kinds is Map<String, dynamic> ? kinds : const {}, k),
      },
      nextName: next is Map<String, dynamic> ? next['name'] as String? : null,
      nextDate: next is Map<String, dynamic>
          ? DateTime.tryParse((next['date'] as String?) ?? '')
          : null,
      nextAmount: next is Map<String, dynamic>
          ? (next['amount'] as num?)?.toDouble()
          : null,
      month: MonthHero.fromJson(json['month']),
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

  /// The list hero: this month's rounds.
  final MonthHero month;

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
    month,
  ];
}

/// The list hero (BE `summary.month`): this calendar month's rounds of the
/// active rules. [expense] leaves out saving and installments; [approx] = some
/// rounds have no amount yet and count their rule's average (shown "~").
class MonthHero extends Equatable {
  const MonthHero({
    this.expense = 0,
    this.approx = false,
    this.paid = 0,
    this.income = 0,
    this.saving = 0,
    this.installment = 0,
  });

  factory MonthHero.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const MonthHero();
    double n(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return MonthHero(
      expense: n('expense'),
      approx: json['expense_approx'] == true,
      paid: n('expense_paid'),
      income: n('income'),
      saving: n('saving'),
      installment: n('installment'),
    );
  }

  final double expense;
  final bool approx;
  final double paid;
  final double income;
  final double saving;
  final double installment;

  double get left => (expense - paid).clamp(0, double.infinity);

  @override
  List<Object?> get props => [
    expense,
    approx,
    paid,
    income,
    saving,
    installment,
  ];
}
