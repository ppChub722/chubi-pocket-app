import 'package:equatable/equatable.dart';

import '../../notifications/domain/notification.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../../ui/ui.dart';

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
IconCode? _icon(Object? v) =>
    v is Map<String, dynamic> ? IconCode.fromJson(v) : null;

/// `GET /v1/dashboard` (contract §4). Month-scoped blocks ([summary],
/// [previous], [topCategories], [trend]) follow [month]; the rest is a
/// "right now" snapshot.
class Dashboard extends Equatable {
  const Dashboard({
    required this.month,
    required this.today,
    required this.netWorth,
    required this.summary,
    required this.previous,
    required this.topCategories,
    required this.otherExpense,
    required this.trend,
    required this.upcoming,
    required this.budgets,
    required this.debts,
    required this.savingGoals,
    required this.recent,
    this.pending = const PendingBlock(),
    this.attention = const AttentionBlock(),
    this.badges = const DashboardBadges(),
  });

  /// First day of the selected month.
  final DateTime month;
  final DateTime today;
  final NetWorth netWorth;
  final PeriodTotals summary;

  /// The month before [month] — for the "vs last month" hint.
  final PeriodTotals previous;
  final List<CategorySlice> topCategories;

  /// Expense outside [topCategories] ("อื่นๆ").
  final double otherExpense;

  /// Oldest → newest, ending at [month].
  final List<TrendPoint> trend;
  final UpcomingBlock upcoming;
  final BudgetsTile budgets;
  final DebtsTile debts;
  final GoalsTile savingGoals;
  final List<Transaction> recent;

  /// Drafts waiting (first 5, resolved) + the total.
  final PendingBlock pending;

  /// Notifications to answer / read (first 10) + the total.
  final AttentionBlock attention;
  final DashboardBadges badges;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String k) =>
        ((json[k] as List?) ?? const []).cast<Map<String, dynamic>>();
    Map<String, dynamic> obj(String k) =>
        (json[k] as Map<String, dynamic>?) ?? const {};
    return Dashboard(
      month: DateTime.parse('${json['month']}-01'),
      today: DateTime.parse(json['today'] as String),
      netWorth: NetWorth.fromJson(obj('net_worth')),
      summary: PeriodTotals.fromJson(obj('summary')),
      previous: PeriodTotals.fromJson(obj('previous')),
      topCategories: list(
        'top_categories',
      ).map(CategorySlice.fromJson).toList(),
      otherExpense: _d(json['other_expense']),
      trend: list('trend').map(TrendPoint.fromJson).toList(),
      upcoming: UpcomingBlock.fromJson(obj('upcoming')),
      budgets: BudgetsTile.fromJson(obj('budgets')),
      debts: DebtsTile.fromJson(obj('debts')),
      savingGoals: GoalsTile.fromJson(obj('saving_goals')),
      recent: list('recent').map(Transaction.fromJson).toList(),
      pending: PendingBlock.fromJson(obj('pending')),
      attention: AttentionBlock.fromJson(obj('attention')),
      badges: DashboardBadges.fromJson(obj('badges')),
    );
  }

  @override
  List<Object?> get props => [
    month,
    today,
    netWorth,
    summary,
    previous,
    topCategories,
    otherExpense,
    trend,
    upcoming,
    budgets,
    debts,
    savingGoals,
    recent,
    pending,
    attention,
    badges,
  ];
}

/// `pending` of the dashboard: [total] drafts, the first few as [items].
class PendingBlock extends Equatable {
  const PendingBlock({this.total = 0, this.items = const []});

  final int total;
  final List<PendingTransaction> items;

  factory PendingBlock.fromJson(Map<String, dynamic> json) => PendingBlock(
    total: _i(json['total']),
    items: ((json['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PendingTransaction.fromJson)
        .toList(),
  );

  @override
  List<Object?> get props => [total, items];
}

/// `attention` of the dashboard: notifications still unread or awaiting an
/// answer — [total] can run past the [items] shown.
class AttentionBlock extends Equatable {
  const AttentionBlock({this.total = 0, this.items = const []});

  final int total;
  final List<AppNotification> items;

  factory AttentionBlock.fromJson(Map<String, dynamic> json) => AttentionBlock(
    total: _i(json['total']),
    items: ((json['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(),
  );

  @override
  List<Object?> get props => [total, items];
}

/// `badges`: the bell and the drafts counts.
class DashboardBadges extends Equatable {
  const DashboardBadges({this.unreadNotifications = 0, this.pendingDrafts = 0});

  final int unreadNotifications;
  final int pendingDrafts;

  factory DashboardBadges.fromJson(Map<String, dynamic> json) =>
      DashboardBadges(
        unreadNotifications: _i(json['unread_notifications']),
        pendingDrafts: _i(json['pending_drafts']),
      );

  @override
  List<Object?> get props => [unreadNotifications, pendingDrafts];
}

class NetWorth extends Equatable {
  const NetWorth({
    required this.total,
    required this.assets,
    required this.liabilities,
    required this.accountsCount,
  });

  final double total;
  final double assets;

  /// Positive number (what's owed on cards / overdrafts).
  final double liabilities;
  final int accountsCount;

  factory NetWorth.fromJson(Map<String, dynamic> json) => NetWorth(
    total: _d(json['total']),
    assets: _d(json['assets']),
    liabilities: _d(json['liabilities']),
    accountsCount: _i(json['accounts_count']),
  );

  @override
  List<Object?> get props => [total, assets, liabilities, accountsCount];
}

class PeriodTotals extends Equatable {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.net,
    required this.count,
  });

  final double income;
  final double expense;
  final double net;
  final int count;

  factory PeriodTotals.fromJson(Map<String, dynamic> json) => PeriodTotals(
    income: _d(json['income']),
    expense: _d(json['expense']),
    net: _d(json['net']),
    count: _i(json['transaction_count']),
  );

  @override
  List<Object?> get props => [income, expense, net, count];
}

/// One top expense category (`top_categories[]`): the category ref (null =
/// uncategorised), its expense and row count.
class CategorySlice extends Equatable {
  const CategorySlice({
    required this.category,
    required this.expense,
    this.count = 0,
  });

  final EmbeddedCategory? category;
  final double expense;
  final int count;

  String? get categoryId => category?.id;
  String get name => category?.name ?? '';
  IconCode? get iconCode => category?.iconCode;

  factory CategorySlice.fromJson(Map<String, dynamic> json) => CategorySlice(
    category: json['category'] is Map<String, dynamic>
        ? EmbeddedCategory.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    expense: _d(json['expense']),
    count: _i(json['count']),
  );

  @override
  List<Object?> get props => [category, expense, count];
}

class TrendPoint extends Equatable {
  const TrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    month: DateTime.parse('${json['month']}-01'),
    income: _d(json['income']),
    expense: _d(json['expense']),
  );

  @override
  List<Object?> get props => [month, income, expense];
}

enum UpcomingKind { recurring, cardDue }

class UpcomingItem extends Equatable {
  const UpcomingItem({
    required this.kind,
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.daysUntil,
    required this.overdue,
    required this.iconCode,
    required this.logoUrl,
  });

  final UpcomingKind kind;

  /// The upcoming recurring item's id, or the account id for
  /// [UpcomingKind.cardDue].
  final String id;
  final String name;
  final TransactionType type;
  final double amount;
  final DateTime dueDate;

  /// Negative when [overdue].
  final int daysUntil;
  final bool overdue;
  final IconCode? iconCode;
  final String? logoUrl;

  factory UpcomingItem.fromJson(Map<String, dynamic> json) => UpcomingItem(
    kind: json['kind'] == 'card_due'
        ? UpcomingKind.cardDue
        : UpcomingKind.recurring,
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    type: json['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense,
    amount: _d(json['amount']),
    dueDate: DateTime.parse(json['due_date'] as String),
    daysUntil: _i(json['days_until']),
    overdue: json['overdue'] as bool? ?? false,
    iconCode: _icon(json['icon_code']),
    logoUrl: json['logo_url'] as String?,
  );

  @override
  List<Object?> get props => [
    kind,
    id,
    name,
    type,
    amount,
    dueDate,
    daysUntil,
    overdue,
    iconCode,
    logoUrl,
  ];
}

class UpcomingBlock extends Equatable {
  const UpcomingBlock({
    required this.days,
    required this.items,
    required this.totalExpense,
    required this.totalIncome,
  });

  final int days;
  final List<UpcomingItem> items;
  final double totalExpense;
  final double totalIncome;

  factory UpcomingBlock.fromJson(Map<String, dynamic> json) => UpcomingBlock(
    days: _i(json['days']),
    items: ((json['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(UpcomingItem.fromJson)
        .toList(),
    totalExpense: _d(json['total_expense']),
    totalIncome: _d(json['total_income']),
  );

  @override
  List<Object?> get props => [days, items, totalExpense, totalIncome];
}

class BudgetsTile extends Equatable {
  const BudgetsTile({
    required this.count,
    required this.totalBudget,
    required this.totalSpent,
    required this.utilizationPct,
    required this.overLimitCount,
  });

  final int count;
  final double totalBudget;
  final double totalSpent;
  final double utilizationPct;
  final int overLimitCount;

  factory BudgetsTile.fromJson(Map<String, dynamic> json) => BudgetsTile(
    count: _i(json['count']),
    totalBudget: _d(json['total_budget']),
    totalSpent: _d(json['total_spent']),
    utilizationPct: _d(json['utilization_pct']),
    overLimitCount: _i(json['over_limit_count']),
  );

  @override
  List<Object?> get props => [
    count,
    totalBudget,
    totalSpent,
    utilizationPct,
    overLimitCount,
  ];
}

class DebtsTile extends Equatable {
  const DebtsTile({
    required this.owedToMe,
    required this.iOwe,
    required this.net,
    required this.openCount,
  });

  final double owedToMe;
  final double iOwe;
  final double net;
  final int openCount;

  factory DebtsTile.fromJson(Map<String, dynamic> json) => DebtsTile(
    owedToMe: _d(json['owed_to_me']),
    iOwe: _d(json['i_owe']),
    net: _d(json['net']),
    openCount: _i(json['open_count']),
  );

  @override
  List<Object?> get props => [owedToMe, iOwe, net, openCount];
}

class GoalsTile extends Equatable {
  const GoalsTile({
    required this.count,
    required this.completedCount,
    required this.totalTarget,
    required this.totalCurrent,
    required this.progressPct,
  });

  final int count;
  final int completedCount;
  final double totalTarget;
  final double totalCurrent;
  final double progressPct;

  factory GoalsTile.fromJson(Map<String, dynamic> json) => GoalsTile(
    count: _i(json['count']),
    completedCount: _i(json['completed_count']),
    totalTarget: _d(json['total_target']),
    totalCurrent: _d(json['total_current']),
    progressPct: _d(json['progress_pct']),
  );

  @override
  List<Object?> get props => [
    count,
    completedCount,
    totalTarget,
    totalCurrent,
    progressPct,
  ];
}
