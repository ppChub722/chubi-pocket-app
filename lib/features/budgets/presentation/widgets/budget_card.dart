import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
  if (cp?.overLimit ?? false) return Tone.danger.color(context);
  if ((cp?.utilizationPct ?? 0) >= 80) return palette.warning;
  return b.iconCode.tintFor(palette);
}

/// Budgets list card: category icon · name · description (when set) ·
/// category · period · progress "฿x จาก ฿y" + % (honours 👁).
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, this.onTap});

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cp = budget.currentPeriod;
    final over = cp?.overLimit ?? false;
    final pct = cp?.utilizationPct ?? 0;
    final category = budget.category?.name ?? '';
    final desc = budget.description?.trim() ?? '';
    // The category only when the name doesn't already say it (the server
    // names a budget after its category by default).
    final subtitle = [
      if (category.isNotEmpty && category != budget.name) category,
      budgetPeriodLabel(l, budget.period),
    ].join(' · ');
    return AppCard(
      onTap: onTap,
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
                    AppText(budget.name, role: AppTextRole.title, maxLines: 1),
                    if (desc.isNotEmpty)
                      AppText(desc, role: AppTextRole.caption, maxLines: 1),
                    AppText(subtitle, role: AppTextRole.caption, maxLines: 1),
                  ],
                ),
              ),
              if (over)
                AppIcon(AppIcons.warning, color: Tone.danger.color(context)),
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
    );
  }
}
