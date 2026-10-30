import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../recurring/domain/recurrence_rule.dart' show parseYmd, ymd;
import '../../transactions/domain/refs.dart';
import 'budget.dart';
import 'budget_period.dart';

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _moneyOrNull(Object? v) => (v as num?)?.toDouble();

enum BudgetSource {
  normal,

  recurring,

  event,

  upcoming,

  pending,

  /// A transaction dated after today: counts as expected until its day.
  futureTx;

  static BudgetSource fromJson(String? v) => switch (v) {
    'future_tx' => BudgetSource.futureTx,
    _ => BudgetSource.values.firstWhere(
      (s) => s.name == v,
      orElse: () => BudgetSource.normal,
    ),
  };

  String toJson() => this == futureTx ? 'future_tx' : name;
}

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

  final double? available;

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

class BudgetSourceRow extends Equatable {
  const BudgetSourceRow({
    required this.source,
    required this.expected,
    required this.count,
    required this.amount,
  });

  final BudgetSource source;

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

class BudgetCategoryRow extends Equatable {
  const BudgetCategoryRow({
    required this.amount,
    required this.pct,
    this.category,
  });

  final EmbeddedCategory? category;
  final double amount;

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
    this.tagIcons = const {},
    this.event,
    this.recurringItemId,
    this.recurringSeq,
    this.recurringTotal,
    this.ruleId,
    this.slot,
    this.reason = BudgetReason.none,
  });

  final BudgetReason reason;

  final String kind;
  final String id;
  final BudgetSource source;
  final bool expected;
  final DateTime? date;

  final double amount;
  final String? description;
  final EmbeddedCategory? category;
  final AccountRef? account;
  final List<String> tags;

  /// The icon of each of the user's own tags by name (from `tag_refs`); a name
  /// that is not one of theirs (an event tag) has no entry.
  final Map<String, IconCode> tagIcons;
  final EventRef? event;

  /// The stored occurrence; null while it is only computed.
  final String? recurringItemId;
  final int? recurringSeq;
  final int? recurringTotal;

  /// A recurring occurrence's address: its setting and its original date.
  final String? ruleId;
  final String? slot;

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
      tagIcons: {
        for (final r in (json['tag_refs'] as List?) ?? const [])
          if (r is Map<String, dynamic> &&
              r['name'] is String &&
              r['icon_code'] is Map<String, dynamic>)
            r['name'] as String: IconCode.fromJson(
              r['icon_code'] as Map<String, dynamic>,
            ),
      },
      event: json['event'] is Map<String, dynamic>
          ? EventRef.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      recurringItemId: recurring?['item_id'] as String?,
      recurringSeq: (recurring?['seq'] as num?)?.toInt(),
      recurringTotal: (recurring?['total'] as num?)?.toInt(),
      ruleId: json['rule_id'] as String?,
      slot: json['slot'] as String?,
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
    tagIcons,
    event,
    recurringItemId,
    recurringSeq,
    recurringTotal,
    ruleId,
    slot,
  ];
}

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

  BudgetItemPage append(BudgetItemPage next) => BudgetItemPage(
    items: [...items, ...next.items],
    page: next.page,
    totalPages: next.totalPages,
    total: next.total,
  );

  @override
  List<Object?> get props => [items, page, totalPages, total];
}

class BudgetDetail extends Equatable {
  const BudgetDetail({
    required this.budget,
    this.forecast = const BudgetForecast(),
    this.bySource = const [],
    this.byCategory = const [],
    this.periods = const BudgetPeriodPage(),
    this.items = const BudgetItemPage(),
    this.deletePreview,
  });

  final Budget budget;
  final BudgetForecast forecast;
  final List<BudgetSourceRow> bySource;
  final List<BudgetCategoryRow> byCategory;

  final BudgetPeriodPage periods;
  final BudgetItemPage items;

  final BudgetDeletePreview? deletePreview;

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
    deletePreview: json['delete_preview'] is Map<String, dynamic>
        ? BudgetDeletePreview.fromJson(
            json['delete_preview'] as Map<String, dynamic>,
          )
        : null,
  );

  @override
  List<Object?> get props => [
    budget,
    forecast,
    bySource,
    byCategory,
    periods,
    items,
    deletePreview,
  ];
}

/// `delete_preview` of GET /budgets/:id — what a delete removes (transactions
/// are never touched).
class BudgetDeletePreview extends Equatable {
  const BudgetDeletePreview({
    required this.periods,
    required this.overriddenPeriods,
    required this.categories,
    required this.wallets,
  });
  final int periods;
  final int overriddenPeriods;
  final int categories;
  final int wallets;

  factory BudgetDeletePreview.fromJson(Map<String, dynamic> json) =>
      BudgetDeletePreview(
        periods: (json['periods'] as num?)?.toInt() ?? 0,
        overriddenPeriods: (json['overridden_periods'] as num?)?.toInt() ?? 0,
        categories: (json['categories'] as num?)?.toInt() ?? 0,
        wallets: (json['wallets'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [periods, overriddenPeriods, categories, wallets];
}

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
