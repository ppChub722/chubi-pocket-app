import 'package:equatable/equatable.dart';

import 'budget_period.dart';
import 'budget_scope.dart';

/// Result of `GET /v1/budgets/overview` (spec §3.7).
///
/// Aggregates spend across all of the caller's active budgets within the
/// requested period + scope. Powers the optional summary card on the
/// budgets list page.
class BudgetOverview extends Equatable {
  const BudgetOverview({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.scope,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallUtilizationPct,
    required this.budgetsOverLimit,
    required this.budgets,
    this.projectId,
  });

  final BudgetPeriod period;
  final String periodStart;
  final String periodEnd;
  final BudgetScope scope;
  final String? projectId;
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double overallUtilizationPct;
  final int budgetsOverLimit;
  final List<BudgetOverviewLine> budgets;

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    final lines = (json['budgets'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(BudgetOverviewLine.fromJson)
        .toList();
    return BudgetOverview(
      period: BudgetPeriod.fromJson(json['period'] as String),
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String,
      scope: BudgetScope.fromJson(json['scope'] as String),
      projectId: json['project_id'] as String?,
      totalBudget: (json['total_budget'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      totalRemaining: (json['total_remaining'] as num).toDouble(),
      overallUtilizationPct:
          (json['overall_utilization_pct'] as num).toDouble(),
      budgetsOverLimit: json['budgets_over_limit'] as int? ?? 0,
      budgets: lines,
    );
  }

  @override
  List<Object?> get props => [
        period,
        periodStart,
        periodEnd,
        scope,
        projectId,
        totalBudget,
        totalSpent,
        totalRemaining,
        overallUtilizationPct,
        budgetsOverLimit,
        budgets,
      ];
}

class BudgetOverviewLine extends Equatable {
  const BudgetOverviewLine({
    required this.id,
    required this.categoryName,
    required this.amount,
    required this.spent,
    required this.overLimit,
    required this.utilizationPct,
  });

  final String id;
  final String categoryName;
  final double amount;
  final double spent;
  final bool overLimit;
  final double utilizationPct;

  factory BudgetOverviewLine.fromJson(Map<String, dynamic> json) {
    return BudgetOverviewLine(
      id: json['id'] as String,
      categoryName: json['category_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      overLimit: json['over_limit'] as bool? ?? false,
      utilizationPct: (json['utilization_pct'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [id, categoryName, amount, spent, overLimit, utilizationPct];
}
