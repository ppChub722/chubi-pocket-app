import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';

String budgetPeriodLabel(AppLocalizations l, BudgetPeriod p) => switch (p) {
  BudgetPeriod.weekly => l.budgetPeriodWeekly,
  BudgetPeriod.monthly => l.budgetPeriodMonthly,
  BudgetPeriod.yearly => l.budgetPeriodYearly,
};

/// "1 ต.ค. 2026 – 31 ต.ค. 2026" from the API's `YYYY-MM-DD` bounds (raw
/// strings if they don't parse).
String budgetPeriodRange(BuildContext context, String start, String end) {
  final l = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toLanguageTag();
  String fmt(String raw) {
    final d = DateFormatter.parseDay(raw);
    return d == null ? raw : DateFormatter.medium(d, locale: locale);
  }

  return l.budgetDetailPeriodRange(fmt(start), fmt(end));
}

/// Bar colour: warning from 80 %, error once over the limit (spec §3).
Color budgetAccent(BuildContext context, Budget b) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final cp = b.currentPeriod;
  if (cp?.overLimit ?? false) return Theme.of(context).colorScheme.error;
  if ((cp?.utilizationPct ?? 0) >= 80) return palette.warning;
  return b.iconCode?.accentColorFor(palette) ?? palette.primary;
}

/// Budgets list card: category icon · title (description, else category)
/// · period · progress "฿x จาก ฿y" + % (honours 👁).
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, this.onTap});

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final cp = budget.currentPeriod;
    final over = cp?.overLimit ?? false;
    final pct = cp?.utilizationPct ?? 0;
    final category = budget.category?.name ?? '';
    final hasDesc = budget.description?.isNotEmpty ?? false;
    final title = hasDesc ? budget.description! : category;
    final subtitle = [
      if (hasDesc && category.isNotEmpty) category,
      budgetPeriodLabel(l, budget.period),
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (over) Icon(AppIcons.warning, color: scheme.error),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ProgressRow(
                value: pct / 100,
                color: budgetAccent(context, budget),
                label: cp == null
                    ? moneyString(context, budget.amount)
                    : l.budgetSpentLine(
                        moneyString(context, cp.spent),
                        moneyString(context, budget.amount),
                      ),
                trailing: '${pct.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
