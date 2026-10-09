import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/budget_overview.dart';
import '../../domain/budget_period.dart';
import 'budget_card.dart';

/// Dashboard card at the top of `/budgets` — totals across every active
/// budget of one period (overview API, spec §3.7): "ใช้ไป ฿x จาก ฿y", the
/// overall bar + %, and "เหลือ ฿z · เกิน n งบ" (honours 👁).
///
/// [periods] lists the periods the user has budgets in; with more than one,
/// a tab bar on top switches [period]. [overview] null → skeleton.
class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({
    required this.periods,
    required this.period,
    required this.onPeriodChanged,
    this.overview,
    super.key,
  });

  final List<BudgetPeriod> periods;
  final BudgetPeriod period;
  final ValueChanged<BudgetPeriod> onPeriodChanged;
  final BudgetOverview? overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final o = overview;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (periods.length > 1)
            AppTabBar<BudgetPeriod>(
              selected: period,
              onChanged: onPeriodChanged,
              tabs: [
                for (final p in periods)
                  AppTab(value: p, label: budgetPeriodLabel(l, p)),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: o == null ? const _Skeleton() : _Content(overview: o),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});
  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final o = overview;
    final pct = o.overallUtilizationPct;
    final accent = o.budgetsOverLimit > 0 || pct > 100
        ? scheme.error
        : pct >= 80
        ? palette.warning
        : palette.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [
            budgetPeriodLabel(l, o.period),
            budgetPeriodRange(context, o.periodStart, o.periodEnd),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l.budgetsOverviewSpent(
            moneyString(context, o.totalSpent),
            moneyString(context, o.totalBudget),
          ),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        ProgressRow(
          value: pct / 100,
          color: accent,
          label: [
            l.budgetDetailRemainingLine(moneyString(context, o.totalRemaining)),
            if (o.budgetsOverLimit > 0)
              l.budgetsOverviewOverCount(o.budgetsOverLimit),
          ].join(' · '),
          trailing: '${pct.toStringAsFixed(0)}%',
        ),
      ],
    );
  }
}

/// Same shape as [_Content] while the overview loads.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 140, height: 10),
        SizedBox(height: AppSpacing.sm),
        SkeletonLine(width: 200, height: 18),
        SizedBox(height: AppSpacing.md),
        SkeletonLine(height: 8),
        SizedBox(height: AppSpacing.sm),
        SkeletonLine(width: 160, height: 10),
      ],
    );
  }
}
