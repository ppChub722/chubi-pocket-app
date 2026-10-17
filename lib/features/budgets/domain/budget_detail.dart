import 'package:equatable/equatable.dart';

import '../../recurring/domain/recurrence_rule.dart' show parseYmd, ymd;
import '../../transactions/domain/refs.dart';
import 'budget.dart';
import 'budget_period.dart';

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _moneyOrNull(Object? v) => (v as num?)?.toDouble();

/// Where a counted amount comes from.
enum BudgetSource {
  /// My transaction.
  normal,

  /// My transaction linked to a recurring item.
  recurring,

  /// My share of an event bill (ONE "อีเวนต์" label).
  event,

  /// A recurring item not made yet (expected).
  upcoming,

  /// A pending draft (expected).
  pending;

  static BudgetSource fromJson(String? v) => BudgetSource.values.firstWhere(
    (s) => s.name == v,
    orElse: () => BudgetSource.normal,
  );

  String toJson() => name;
}

/// Why a counted row counts in the budget (first match; `item.reason`).
enum BudgetReason {
  all,
  category,
  subCategory,
  tag,
  wallet,

  /// Nothing matched (never for a counted row).
  none;

  static BudgetReason fromJson(String? v) => switch (v) {
    'all' => BudgetReason.all,
    'category' => BudgetReason.category,
    'sub_category' => BudgetReason.subCategory,
    'tag' => BudgetReason.tag,
    'wallet' => BudgetReason.wallet,
    _ => BudgetReason.none,
  };
}

/// The period dashboard ("ภาพรวม"); a figure that doesn't apply is null.
class BudgetForecast extends Equatable {
  const BudgetForecast({
    this.elapsedDays,
    this.totalDays,
    this.dailyAllowance,
    this.avgDaily,
    this.avgMonthly,
    this.forecastEnd,
    this.forecastOverBy,
    this.forecastOverDate,
    this.remainingAfterExpected = 0,
    this.thisMonth,
    this.historyAvg,
    this.historyCount = 0,
    this.available,
    this.projectedEnd,
    this.daysLeft,
    this.pacePct,
  });

  /// limit − used (this period).
  final double? available;

  /// Where the current period ends at the current pace (= [forecastEnd]);
  /// null when open-ended or not current.
  final double? projectedEnd;

  /// Days left in the current period, today included; null otherwise.
  final int? daysLeft;

  /// How much of the period has elapsed (0–100) — the pace tick; null
  /// otherwise.
  final int? pacePct;

  final int? elapsedDays;
  final int? totalDays;
  final double? dailyAllowance;
  final double? avgDaily;
  final double? avgMonthly;
  final double? forecastEnd;
  final double? forecastOverBy;
  final DateTime? forecastOverDate;
  final double remainingAfterExpected;
  final double? thisMonth;
  final double? historyAvg;
  final int historyCount;

  factory BudgetForecast.fromJson(Map<String, dynamic>? json) => BudgetForecast(
    elapsedDays: (json?['elapsed_days'] as num?)?.toInt(),
    totalDays: (json?['total_days'] as num?)?.toInt(),
    dailyAllowance: _moneyOrNull(json?['daily_allowance']),
    avgDaily: _moneyOrNull(json?['avg_daily']),
    avgMonthly: _moneyOrNull(json?['avg_monthly']),
    forecastEnd: _moneyOrNull(json?['forecast_end']),
    forecastOverBy: _moneyOrNull(json?['forecast_over_by']),
    forecastOverDate: parseYmd(json?['forecast_over_date'] as String?),
    remainingAfterExpected: _money(json?['remaining_after_expected']),
    thisMonth: _moneyOrNull(json?['this_month']),
    historyAvg: _moneyOrNull(json?['history_avg']),
    historyCount: (json?['history_count'] as num?)?.toInt() ?? 0,
    available: _moneyOrNull(json?['available']),
    projectedEnd: _moneyOrNull(json?['projected_end']),
    daysLeft: (json?['days_left'] as num?)?.toInt(),
    pacePct: (json?['pace_pct'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [
    available,
    projectedEnd,
    daysLeft,
    pacePct,
    elapsedDays,
    totalDays,
    dailyAllowance,
    avgDaily,
    avgMonthly,
    forecastEnd,
    forecastOverBy,
    forecastOverDate,
    remainingAfterExpected,
    thisMonth,
    historyAvg,
    historyCount,
  ];
}

/// One row of "แยกตามที่มา".
class BudgetSourceRow extends Equatable {
  const BudgetSourceRow({
    required this.source,
    required this.expected,
    required this.count,
    required this.amount,
  });

  final BudgetSource source;

  /// `counts_as: expected` (upcoming / pending) — not in the %.
  final bool expected;
  final int count;
  final double amount;

  factory BudgetSourceRow.fromJson(Map<String, dynamic> json) =>
      BudgetSourceRow(
        source: BudgetSource.fromJson(json['source'] as String?),
        expected: json['counts_as'] == 'expected',
        count: (json['count'] as num?)?.toInt() ?? 0,
        amount: _money(json['amount']),
      );

  @override
  List<Object?> get props => [source, expected, count, amount];
}

/// One row of "แยกตามหมวด" (used only).
class BudgetCategoryRow extends Equatable {
  const BudgetCategoryRow({
    required this.amount,
    required this.pct,
    this.category,
  });

  /// Null = no category (e.g. an event bill not made from my transaction).
  final EmbeddedCategory? category;
  final double amount;

  /// Share of used.
  final int pct;

  factory BudgetCategoryRow.fromJson(Map<String, dynamic> json) =>
      BudgetCategoryRow(
        category: json['category'] is Map<String, dynamic>
            ? EmbeddedCategory.fromJson(
                json['category'] as Map<String, dynamic>,
              )
            : null,
        amount: _money(json['amount']),
        pct: (json['pct'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [category, amount, pct];
}

/// One thing counted in a period.
class BudgetItem extends Equatable {
  const BudgetItem({
    required this.kind,
    required this.id,
    required this.source,
    required this.expected,
    required this.amount,
    this.date,
    this.description,
    this.category,
    this.account,
    this.tags = const [],
    this.event,
    this.recurringItemId,
    this.recurringSeq,
    this.recurringTotal,
    this.reason = BudgetReason.none,
  });

  /// Why this row counts in the budget.
  final BudgetReason reason;

  /// `transaction` | `event_bill` | `recurring_item` | `pending` — what [id]
  /// points at.
  final String kind;
  final String id;
  final BudgetSource source;
  final bool expected;
  final DateTime? date;

  /// My share.
  final double amount;
  final String? description;
  final EmbeddedCategory? category;
  final AccountRef? account;
  final List<String> tags;
  final EventRef? event;
  final String? recurringItemId;
  final int? recurringSeq;
  final int? recurringTotal;

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    final recurring = json['recurring'] as Map<String, dynamic>?;
    return BudgetItem(
      kind: (json['kind'] as String?) ?? 'transaction',
      id: json['id'] as String,
      source: BudgetSource.fromJson(json['source'] as String?),
      expected: json['counts_as'] == 'expected',
      date: parseYmd(json['date'] as String?),
      amount: _money(json['amount']),
      description: json['description'] as String?,
      category: json['category'] is Map<String, dynamic>
          ? EmbeddedCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      account: json['account'] is Map<String, dynamic>
          ? AccountRef.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      tags: [for (final t in (json['tags'] as List?) ?? const []) t as String],
      event: json['event'] is Map<String, dynamic>
          ? EventRef.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      recurringItemId: recurring?['item_id'] as String?,
      recurringSeq: (recurring?['seq'] as num?)?.toInt(),
      recurringTotal: (recurring?['total'] as num?)?.toInt(),
      reason: BudgetReason.fromJson(json['reason'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    reason,
    kind,
    id,
    source,
    expected,
    date,
    amount,
    description,
    category,
    account,
    tags,
    event,
    recurringItemId,
    recurringSeq,
    recurringTotal,
  ];
}

/// A page of counted items (expected first, then used newest first).
class BudgetItemPage extends Equatable {
  const BudgetItemPage({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  final List<BudgetItem> items;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  factory BudgetItemPage.fromJson(Map<String, dynamic>? json) {
    final p = json?['pagination'] as Map<String, dynamic>?;
    return BudgetItemPage(
      items: [
        for (final i in (json?['data'] as List?) ?? const [])
          BudgetItem.fromJson(i as Map<String, dynamic>),
      ],
      page: (p?['page'] as num?)?.toInt() ?? 1,
      totalPages: (p?['total_pages'] as num?)?.toInt() ?? 1,
      total: (p?['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// This page followed by [next].
  BudgetItemPage append(BudgetItemPage next) => BudgetItemPage(
    items: [...items, ...next.items],
    page: next.page,
    totalPages: next.totalPages,
    total: next.total,
  );

  @override
  List<Object?> get props => [items, page, totalPages, total];
}

/// `getBudget` (and every write): the budget page in one call, at the period
/// `budget.period`.
class BudgetDetail extends Equatable {
  const BudgetDetail({
    required this.budget,
    this.forecast = const BudgetForecast(),
    this.bySource = const [],
    this.byCategory = const [],
    this.periods = const BudgetPeriodPage(),
    this.items = const BudgetItemPage(),
  });

  final Budget budget;
  final BudgetForecast forecast;
  final List<BudgetSourceRow> bySource;
  final List<BudgetCategoryRow> byCategory;

  /// The 6 newest periods (recurring); `hasMore` → `listBudgetPeriods`.
  final BudgetPeriodPage periods;
  final BudgetItemPage items;

  BudgetDetail copyWith({
    Budget? budget,
    BudgetPeriodPage? periods,
    BudgetItemPage? items,
  }) => BudgetDetail(
    budget: budget ?? this.budget,
    forecast: forecast,
    bySource: bySource,
    byCategory: byCategory,
    periods: periods ?? this.periods,
    items: items ?? this.items,
  );

  /// The page after `updateBudgetPeriod` answered with [next] — the budget
  /// page AT THE EDITED PERIOD. The current period's answer replaces this
  /// page; an older period's answer only patches that period's row (the page
  /// keeps showing the current one).
  BudgetDetail afterPeriodWrite(BudgetDetail next) {
    if (next.budget.period.id == budget.period.id) return next;
    return copyWith(periods: periods.replace(next.budget.period));
  }

  factory BudgetDetail.fromJson(Map<String, dynamic> json) => BudgetDetail(
    budget: Budget.fromJson(json['budget'] as Map<String, dynamic>),
    forecast: BudgetForecast.fromJson(
      json['forecast'] as Map<String, dynamic>?,
    ),
    bySource: [
      for (final r in (json['by_source'] as List?) ?? const [])
        BudgetSourceRow.fromJson(r as Map<String, dynamic>),
    ],
    byCategory: [
      for (final r in (json['by_category'] as List?) ?? const [])
        BudgetCategoryRow.fromJson(r as Map<String, dynamic>),
    ],
    periods: BudgetPeriodPage.fromJson(
      json['periods'] as Map<String, dynamic>?,
    ),
    items: BudgetItemPage.fromJson(json['items'] as Map<String, dynamic>?),
  );

  @override
  List<Object?> get props => [
    budget,
    forecast,
    bySource,
    byCategory,
    periods,
    items,
  ];
}

/// The body of `createBudget` / `updateBudget` (setup, "ตั้งค่า").
class BudgetWrite {
  const BudgetWrite({
    required this.name,
    required this.amount,
    required this.scope,
    required this.startDate,
    required this.recurring,
    this.description,
    this.note,
    this.iconCode,
    this.warnPct,
    this.rule,
    this.end = const BudgetEnd.none(),
  });

  final String name;
  final String? description;
  final String? note;
  final Object? iconCode;
  final double amount;

  /// Null = ไม่เตือน.
  final int? warnPct;
  final BudgetScope scope;
  final bool recurring;
  final BudgetRule? rule;
  final DateTime startDate;
  final BudgetEnd end;

  Map<String, dynamic> toJson({String? apply}) => {
    'name': name,
    'description': description,
    'note': note,
    if (iconCode != null) 'icon_code': iconCode,
    'amount': amount,
    'warn_pct': warnPct,
    'scope': scope.toInputJson(),
    'recurring': recurring,
    if (recurring && rule != null) 'rule': rule!.toJson(),
    'start_date': ymd(startDate),
    'end': {
      'kind': end.kind,
      if (end.kind == 'date' && end.date != null) 'date': ymd(end.date!),
      if (end.kind == 'count') 'count': end.count,
    },
    'apply': ?apply,
  };
}
