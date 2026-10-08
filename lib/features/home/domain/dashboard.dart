import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

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
  ];
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

/// One top-level expense category. [categoryId] null = uncategorized.
class CategorySlice extends Equatable {
  const CategorySlice({
    required this.categoryId,
    required this.name,
    required this.iconCode,
    required this.expense,
  });

  final String? categoryId;
  final String name;
  final IconCode? iconCode;
  final double expense;

  factory CategorySlice.fromJson(Map<String, dynamic> json) => CategorySlice(
    categoryId: json['category_id'] as String?,
    name: json['name'] as String? ?? '',
    iconCode: _icon(json['icon_code']),
    expense: _d(json['expense']),
  );

  @override
  List<Object?> get props => [categoryId, name, iconCode, expense];
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

enum UpcomingKind { scheduled, cardDue }

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

  /// Scheduled transaction id, or the account id for [UpcomingKind.cardDue].
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
        : UpcomingKind.scheduled,
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
