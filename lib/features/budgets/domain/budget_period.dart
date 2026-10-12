import 'package:equatable/equatable.dart';

import '../../recurring/domain/recurrence_rule.dart' show parseYmd;

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;

/// A period's BE status: over > warn > pace > ok (`pace` = the current
/// period is on course to pass its amount; only the current period).
enum BudgetStatus {
  ok,
  pace,
  warn,
  over;

  static BudgetStatus fromJson(String? v) => BudgetStatus.values.firstWhere(
    (s) => s.name == v,
    orElse: () => BudgetStatus.ok,
  );
}

/// The BE's tone for a status (`neutral` / `warning` / `danger`).
enum BudgetTone {
  neutral,
  warning,
  danger;

  static BudgetTone fromJson(String? v) => BudgetTone.values.firstWhere(
    (t) => t.name == v,
    orElse: () => BudgetTone.neutral,
  );
}

/// One period (an instance) of a budget, with its own amount / note.
/// Every figure is computed by the BE (`BudgetPeriod` in the spec).
class BudgetPeriod extends Equatable {
  const BudgetPeriod({
    required this.id,
    required this.seq,
    required this.start,
    required this.amount,
    required this.baseAmount,
    this.end,
    this.overridden = false,
    this.note,
    this.isCurrent = false,
    this.used = 0,
    this.expected = 0,
    this.remaining = 0,
    this.overBy = 0,
    this.pct = 0,
    this.status = BudgetStatus.ok,
    this.tone = BudgetTone.neutral,
    this.daysLeft,
  });

  final String id;
  final int seq;
  final DateTime start;

  /// Null = open-ended.
  final DateTime? end;
  final double amount;

  /// The setup amount; differs from [amount] when [overridden].
  final double baseAmount;

  /// Set for this period only ("✏️ เฉพาะรอบนี้").
  final bool overridden;
  final String? note;
  final bool isCurrent;
  final double used;

  /// Upcoming + pending (current period only); not in [pct] / [remaining].
  final double expected;
  final double remaining;
  final double overBy;

  /// used / amount, rounded, NOT clamped.
  final int pct;
  final BudgetStatus status;
  final BudgetTone tone;

  /// Today included; null for past / open-ended periods.
  final int? daysLeft;

  /// used / amount as a bar ratio (0 when the amount is 0).
  double get usedRatio => amount <= 0 ? 0 : used / amount;

  /// expected / amount as a bar ratio.
  double get expectedRatio => amount <= 0 ? 0 : expected / amount;

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) => BudgetPeriod(
    id: json['id'] as String,
    seq: (json['seq'] as num?)?.toInt() ?? 1,
    start: parseYmd(json['start'] as String?) ?? DateTime.now(),
    end: parseYmd(json['end'] as String?),
    amount: _money(json['amount']),
    baseAmount: _money(json['base_amount'] ?? json['amount']),
    overridden: json['overridden'] as bool? ?? false,
    note: json['note'] as String?,
    isCurrent: json['is_current'] as bool? ?? false,
    used: _money(json['used']),
    expected: _money(json['expected']),
    remaining: _money(json['remaining']),
    overBy: _money(json['over_by']),
    pct: (json['pct'] as num?)?.toInt() ?? 0,
    status: BudgetStatus.fromJson(json['status'] as String?),
    tone: BudgetTone.fromJson(json['tone'] as String?),
    daysLeft: (json['days_left'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [
    id,
    seq,
    start,
    end,
    amount,
    baseAmount,
    overridden,
    note,
    isCurrent,
    used,
    expected,
    remaining,
    overBy,
    pct,
    status,
    tone,
    daysLeft,
  ];
}

/// A page of periods (`periods` of the detail, `listBudgetPeriods`).
class BudgetPeriodPage extends Equatable {
  const BudgetPeriodPage({
    this.periods = const [],
    this.hasMore = false,
    this.page = 1,
  });

  final List<BudgetPeriod> periods;
  final bool hasMore;
  final int page;

  factory BudgetPeriodPage.fromJson(Map<String, dynamic>? json) {
    final data = (json?['data'] as List?) ?? const [];
    final pagination = json?['pagination'] as Map<String, dynamic>?;
    final page = (pagination?['page'] as num?)?.toInt() ?? 1;
    final totalPages = (pagination?['total_pages'] as num?)?.toInt() ?? 1;
    return BudgetPeriodPage(
      periods: [
        for (final p in data) BudgetPeriod.fromJson(p as Map<String, dynamic>),
      ],
      hasMore: json?['has_more'] as bool? ?? page < totalPages,
      page: page,
    );
  }

  /// This page followed by [next].
  BudgetPeriodPage append(BudgetPeriodPage next) => BudgetPeriodPage(
    periods: [...periods, ...next.periods],
    hasMore: next.hasMore,
    page: next.page,
  );

  @override
  List<Object?> get props => [periods, hasMore, page];
}
