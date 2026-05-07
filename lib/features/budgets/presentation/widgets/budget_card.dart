import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';

/// Tappable card for the budgets list.
///
/// Anatomy per design-sheet §8.3 (`BudgetCard`): category icon · period
/// · progress bar · spent / limit · over-limit warning. Bar shifts to
/// `warning` at 80% and `error` at 100% (spec §3 visual rule).
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
  });

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final cp = budget.currentPeriod;
    final overLimit = cp?.overLimit ?? false;
    final utilization = cp?.utilizationPct ?? 0;
    final progress = (utilization / 100).clamp(0.0, 1.0);
    final accent = overLimit
        ? scheme.error
        : utilization >= 80
            ? Colors.orange
            : (budget.iconCode?.accentColorFor(palette) ?? scheme.primary);
    final categoryName = budget.category?.name ?? '';
    final hasDescription =
        budget.description != null && budget.description!.isNotEmpty;
    // Title prefers description; secondary line shows the category name
    // + period. When no description, the category name moves up to the
    // title slot and the secondary line just carries the period.
    final primary = hasDescription ? budget.description! : categoryName;
    final secondary = hasDescription
        ? '$categoryName · ${_periodLabel(l, budget.period)}'
        : _periodLabel(l, budget.period);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconDisplay(
                    type: IconType.category,
                    size: 40,
                    iconCode: budget.iconCode,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primary,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          secondary,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (overLimit)
                    Icon(Icons.warning_amber_rounded, color: scheme.error),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cp != null
                        ? l.budgetSpentLine(
                            CurrencyFormatter.format(cp.spent),
                            CurrencyFormatter.format(budget.amount),
                          )
                        : CurrencyFormatter.format(budget.amount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${utilization.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _periodLabel(AppLocalizations l, BudgetPeriod p) {
    switch (p) {
      case BudgetPeriod.weekly:
        return l.budgetPeriodWeekly;
      case BudgetPeriod.monthly:
        return l.budgetPeriodMonthly;
      case BudgetPeriod.yearly:
        return l.budgetPeriodYearly;
    }
  }
}
