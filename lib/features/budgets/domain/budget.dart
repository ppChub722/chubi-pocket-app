import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../recurring/domain/recurrence_rule.dart' show parseYmd;
import '../../transactions/domain/refs.dart';
import 'budget_period.dart';

double _money(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Where a budget is in its life: `upcoming` starts after today, `ended` =
/// closed (ปิดงบ) or past its end.
enum BudgetState {
  upcoming,
  active,
  ended,
  archived;

  static BudgetState fromJson(String? v) => BudgetState.values.firstWhere(
    (s) => s.name == v,
    orElse: () => BudgetState.active,
  );
}

/// The list filter (`status` of `listBudgets`).
enum BudgetFilter {
  active,
  ended,
  archived;

  String toJson() => name;
}

/// The health tile of the list (`health` of `listBudgets`); [all] = no param.
enum BudgetHealth {
  all,
  normal,
  near,
  over;

  String? toJson() => this == BudgetHealth.all ? null : name;
}

/// The list sort (`sort` of `listBudgets`).
enum BudgetSort {
  risk,
  alphabetical,
  newest;

  String toJson() => switch (this) {
    BudgetSort.risk => 'risk',
    BudgetSort.alphabetical => 'name',
    BudgetSort.newest => 'newest',
  };
}

/// A recurring budget's period length: every [interval] [freq]s.
class BudgetRule extends Equatable {
  const BudgetRule({required this.freq, this.interval = 1});

  /// `daily` | `weekly` | `monthly` | `yearly`.
  final String freq;
  final int interval;

  factory BudgetRule.fromJson(Map<String, dynamic> json) => BudgetRule(
    freq: (json['freq'] as String?) ?? 'monthly',
    interval: (json['interval'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {'freq': freq, 'interval': interval};

  @override
  List<Object?> get props => [freq, interval];
}

/// Where a budget stops (`RecurrenceEnd`): none | date | count (periods).
class BudgetEnd extends Equatable {
  const BudgetEnd.none() : kind = 'none', date = null, count = null;
  const BudgetEnd.onDate(DateTime this.date) : kind = 'date', count = null;
  const BudgetEnd.afterCount(int this.count) : kind = 'count', date = null;

  final String kind;
  final DateTime? date;
  final int? count;

  factory BudgetEnd.fromJson(Map<String, dynamic>? json) {
    switch (json?['kind']) {
      case 'date':
        final d = parseYmd(json?['date'] as String?);
        if (d != null) return BudgetEnd.onDate(d);
      case 'count':
        final c = (json?['count'] as num?)?.toInt();
        if (c != null) return BudgetEnd.afterCount(c);
    }
    return const BudgetEnd.none();
  }

  @override
  List<Object?> get props => [kind, date, count];
}

/// One category a budget counts, with its sub-categories or not.
class BudgetScopeCategory extends Equatable {
  const BudgetScopeCategory({
    required this.category,
    this.includeChildren = true,
  });

  final EmbeddedCategory category;
  final bool includeChildren;

  factory BudgetScopeCategory.fromJson(Map<String, dynamic> json) =>
      BudgetScopeCategory(
        category: EmbeddedCategory.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        includeChildren: json['include_children'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [category, includeChildren];
}

/// What a budget counts: every expense, or a row that matches ANY of the
/// listed categories / tag NAMES / wallets.
class BudgetScope extends Equatable {
  const BudgetScope({
    this.all = false,
    this.categories = const [],
    this.tags = const [],
    this.wallets = const [],
  });

  final bool all;
  final List<BudgetScopeCategory> categories;
  final List<String> tags;
  final List<AccountRef> wallets;

  bool get isEmpty =>
      !all && categories.isEmpty && tags.isEmpty && wallets.isEmpty;

  factory BudgetScope.fromJson(Map<String, dynamic>? json) => BudgetScope(
    all: json?['all'] as bool? ?? false,
    categories: [
      for (final c in (json?['categories'] as List?) ?? const [])
        BudgetScopeCategory.fromJson(c as Map<String, dynamic>),
    ],
    tags: [for (final t in (json?['tags'] as List?) ?? const []) t as String],
    wallets: [
      for (final w in (json?['wallets'] as List?) ?? const [])
        AccountRef.fromJson(w as Map<String, dynamic>),
    ],
  );

  /// The request shape (`BudgetScopeInput`).
  Map<String, dynamic> toInputJson() => {
    'all': all,
    'categories': [
      for (final c in categories)
        {'id': c.category.id, 'include_children': c.includeChildren},
    ],
    'tags': tags,
    'wallet_ids': [for (final w in wallets) w.id],
  };

  @override
  List<Object?> get props => [all, categories, tags, wallets];
}

/// What the BE lets the caller do with this budget right now.
class BudgetActions extends Equatable {
  const BudgetActions({
    this.edit = true,
    this.close = false,
    this.archive = true,
    this.restore = false,
  });

  final bool edit;
  final bool close;
  final bool archive;
  final bool restore;

  factory BudgetActions.fromJson(Map<String, dynamic>? json) => BudgetActions(
    edit: json?['edit'] as bool? ?? true,
    close: json?['close'] as bool? ?? false,
    archive: json?['archive'] as bool? ?? true,
    restore: json?['restore'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [edit, close, archive, restore];
}

/// A budget — a NAMED personal tracker (spec 08 v2) — with the one
/// [period] it is shown at (the list: the current one; an ended budget: the
/// last). Everything is computed by the BE.
class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.scope,
    required this.startDate,
    required this.period,
    this.description,
    this.note,
    this.iconCode,
    this.warnPct = 80,
    this.recurring = false,
    this.rule,
    this.end = const BudgetEnd.none(),
    this.state = BudgetState.active,
    this.closedOn,
    this.actions = const BudgetActions(),
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? note;
  final IconCode? iconCode;

  /// The base amount per period.
  final double amount;

  /// Null = ไม่เตือน.
  final int? warnPct;
  final BudgetScope scope;

  /// "งบระยะยาว".
  final bool recurring;
  final BudgetRule? rule;
  final DateTime startDate;
  final BudgetEnd end;
  final BudgetState state;
  final DateTime? closedOn;
  final BudgetPeriod period;
  final BudgetActions actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// One range with no end: open until ปิดงบ.
  bool get openEnded => !recurring && end.kind == 'none';

  /// A fixed range (not recurring) that ends by itself.
  bool get oneOff => !recurring && end.kind == 'date';

  bool get isArchived => state == BudgetState.archived;
  bool get isEnded => state == BudgetState.ended;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    description: json['description'] as String?,
    note: json['note'] as String?,
    iconCode: json['icon_code'] is Map<String, dynamic>
        ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
        : null,
    amount: _money(json['amount']),
    warnPct: (json['warn_pct'] as num?)?.toInt(),
    scope: BudgetScope.fromJson(json['scope'] as Map<String, dynamic>?),
    recurring: json['recurring'] as bool? ?? false,
    rule: json['rule'] is Map<String, dynamic>
        ? BudgetRule.fromJson(json['rule'] as Map<String, dynamic>)
        : null,
    startDate: parseYmd(json['start_date'] as String?) ?? DateTime.now(),
    end: BudgetEnd.fromJson(json['end'] as Map<String, dynamic>?),
    state: BudgetState.fromJson(json['state'] as String?),
    closedOn: parseYmd(json['closed_on'] as String?),
    period: BudgetPeriod.fromJson(json['period'] as Map<String, dynamic>),
    actions: BudgetActions.fromJson(json['actions'] as Map<String, dynamic>?),
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    note,
    iconCode,
    amount,
    warnPct,
    scope,
    recurring,
    rule,
    startDate,
    end,
    state,
    closedOn,
    period,
    actions,
    createdAt,
    updatedAt,
  ];
}

/// The list header: the counts the chips and the hero show.
class BudgetListSummary extends Equatable {
  const BudgetListSummary({
    this.activeCount = 0,
    this.overCount = 0,
    this.warnCount = 0,
    this.paceCount = 0,
    this.endedCount = 0,
    this.archivedCount = 0,
    this.totalLimit = 0,
    this.totalUsed = 0,
    this.totalRemaining = 0,
    this.usedPct = 0,
    this.countAll = 0,
    this.countOk = 0,
    this.countNear = 0,
    this.countOver = 0,
  });

  final int activeCount;
  final int overCount;
  final int warnCount;
  final int paceCount;
  final int endedCount;
  final int archivedCount;

  /// Active budgets at their current period: the plain sum of the amounts.
  final double totalLimit;
  final double totalUsed;

  /// limit - used (negative when over).
  final double totalRemaining;
  final int usedPct;

  /// The health tiles: all = ok + near + over.
  final int countAll;
  final int countOk;
  final int countNear;
  final int countOver;

  factory BudgetListSummary.fromJson(Map<String, dynamic>? json) {
    int n(String k) => (json?[k] as num?)?.toInt() ?? 0;
    final counts = json?['counts'] as Map<String, dynamic>?;
    int c(String k) => (counts?[k] as num?)?.toInt() ?? 0;
    return BudgetListSummary(
      activeCount: n('active_count'),
      overCount: n('over_count'),
      warnCount: n('warn_count'),
      paceCount: n('pace_count'),
      endedCount: n('ended_count'),
      archivedCount: n('archived_count'),
      totalLimit: _money(json?['total_limit']),
      totalUsed: _money(json?['total_used']),
      totalRemaining: _money(json?['total_remaining']),
      usedPct: n('used_pct'),
      countAll: c('all'),
      countOk: c('ok'),
      countNear: c('near'),
      countOver: c('over'),
    );
  }

  @override
  List<Object?> get props => [
    activeCount,
    overCount,
    warnCount,
    paceCount,
    endedCount,
    archivedCount,
    totalLimit,
    totalUsed,
    totalRemaining,
    usedPct,
    countAll,
    countOk,
    countNear,
    countOver,
  ];
}

/// `listBudgets`: the summary + each budget at its current period.
class BudgetList extends Equatable {
  const BudgetList({
    this.summary = const BudgetListSummary(),
    this.budgets = const [],
  });

  final BudgetListSummary summary;
  final List<Budget> budgets;

  factory BudgetList.fromJson(Map<String, dynamic> json) => BudgetList(
    summary: BudgetListSummary.fromJson(
      json['summary'] as Map<String, dynamic>?,
    ),
    budgets: [
      for (final b in (json['data'] as List?) ?? const [])
        Budget.fromJson(b as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [summary, budgets];
}
