import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';
import '../domain/budget_period.dart';

// Words and small mappers only: models → kit parameters (no styling).

/// "รายเดือน" / "ทุก 2 เดือน" — a recurring budget's period length.
String budgetRuleLabel(AppLocalizations l, BudgetRule rule) {
  final n = rule.interval < 1 ? 1 : rule.interval;
  if (n == 1) {
    return switch (rule.freq) {
      'daily' => l.bgRuleDaily,
      'weekly' => l.bgRuleWeekly,
      'yearly' => l.bgRuleYearly,
      _ => l.bgRuleMonthly,
    };
  }
  return switch (rule.freq) {
    'daily' => l.recurEveryDays(n),
    'weekly' => l.recurEveryWeeks(n),
    'yearly' => l.recurEveryYears(n),
    _ => l.recurEveryMonths(n),
  };
}

String _day(BuildContext context, DateTime d) => DateFormatter.medium(
  d,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

/// A date as the pages show it ("8 ต.ค. 2026").
String budgetDate(BuildContext context, DateTime d) => _day(context, d);

/// "1 ต.ค. 2026 – 31 ต.ค. 2026"; an open end shows "ตั้งแต่ 1 ส.ค. 2026".
String budgetRange(BuildContext context, DateTime start, DateTime? end) {
  final l = AppLocalizations.of(context)!;
  if (end == null) return l.bgRowSince(_day(context, start));
  return l.bgRowRange(_day(context, start), _day(context, end));
}

/// The period's name: a month for a monthly rule, else its range.
String budgetPeriodTitle(BuildContext context, Budget budget, BudgetPeriod p) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  if (budget.rule?.freq == 'monthly' && (budget.rule?.interval ?? 1) == 1) {
    return DateFormatter.monthYear(p.start, locale: locale);
  }
  if (budget.rule?.freq == 'yearly' && (budget.rule?.interval ?? 1) == 1) {
    return p.start.year.toString();
  }
  return budgetRange(context, p.start, p.end);
}

/// The status chip of a budget row / hero (null = nothing to flag).
Widget? budgetStatusChip(
  AppLocalizations l,
  Budget budget, {
  BudgetPeriod? period,
  ChipSize? size,
}) {
  final p = period ?? budget.period;
  switch (budget.state) {
    case BudgetState.archived:
      return StatusChip(
        label: l.bgStatusArchived,
        kind: StatusKind.archived,
        size: size,
      );
    case BudgetState.ended:
      return StatusChip(
        label: l.bgStatusEnded,
        kind: StatusKind.done,
        size: size,
      );
    case BudgetState.upcoming:
      return StatusChip(
        label: l.bgStatusUpcoming,
        kind: StatusKind.upcoming,
        size: size,
      );
    case BudgetState.active:
      break;
  }
  return switch (p.status) {
    BudgetStatus.over => StatusChip(
      label: l.bgStatusOver,
      kind: StatusKind.over,
      size: size,
    ),
    BudgetStatus.warn => StatusChip(
      label: l.bgStatusWarn,
      kind: StatusKind.warning,
      size: size,
    ),
    BudgetStatus.pace => StatusChip.tone(
      label: l.bgStatusPace,
      tone: AppChipTone.neutral,
      size: size,
    ),
    BudgetStatus.ok => null,
  };
}

/// The source's name on a breakdown row / an item.
String budgetSourceLabel(AppLocalizations l, BudgetSource s) => switch (s) {
  BudgetSource.normal => l.bgSourceNormal,
  BudgetSource.recurring => l.bgSourceRecurring,
  BudgetSource.event => l.bgSourceEvent,
  BudgetSource.upcoming => l.bgSourceUpcoming,
  BudgetSource.pending => l.bgSourcePending,
};

/// The kit tone of a period: the BE's tone, never derived from the ratio.
ProgressTone budgetProgressTone(BudgetPeriod p) => switch (p.tone) {
  BudgetTone.danger => ProgressTone.danger,
  BudgetTone.warning => ProgressTone.warning,
  BudgetTone.neutral => ProgressTone.neutral,
};

/// A budget's own tint (its icon colour) — what a neutral tone resolves to.
Color budgetTint(BuildContext context, Budget budget) =>
    budget.iconCode.tintFor(Theme.of(context).extension<AppColors>()!);

/// The hero accent: the tone colour, else the budget's tint.
Color budgetToneColor(BuildContext context, Budget budget, BudgetPeriod p) =>
    budgetProgressTone(
      p,
    ).resolve(context, entityTint: budgetTint(context, budget));
