import 'package:equatable/equatable.dart';

import '../../recurring/domain/recurrence_rule.dart' show parseYmd;

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;

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

enum BudgetTone {
  neutral,
  warning,
  danger;

  static BudgetTone fromJson(String? v) => BudgetTone.values.firstWhere(
    (t) => t.name == v,
    orElse: () => BudgetTone.neutral,
  );
}

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
    this.onPaceToExceed = false,
  });

  final String id;
  final int seq;
  final DateTime start;

  final DateTime? end;
  final double amount;

  final double baseAmount;

  final bool overridden;
  final String? note;
  final bool isCurrent;
  final double used;

  final double expected;
  final double remaining;
  final double overBy;

  final int pct;
  final BudgetStatus status;
  final BudgetTone tone;

  final int? daysLeft;

  final bool onPaceToExceed;

  double get usedRatio => amount <= 0 ? 0 : used / amount;

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
    onPaceToExceed: json['on_pace_to_exceed'] as bool? ?? false,
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
    onPaceToExceed,
  ];
}

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

  BudgetPeriodPage replace(BudgetPeriod p) => BudgetPeriodPage(
    periods: [for (final x in periods) x.id == p.id ? p : x],
    hasMore: hasMore,
    page: page,
  );

  BudgetPeriodPage append(BudgetPeriodPage next) => BudgetPeriodPage(
    periods: [...periods, ...next.periods],
    hasMore: next.hasMore,
    page: next.page,
  );

  @override
  List<Object?> get props => [periods, hasMore, page];
}
