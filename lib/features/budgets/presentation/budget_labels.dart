import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/refs.dart';
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

/// The row's bar tone: the BE's neutral reads as the primary (teal) bar, then
/// amber (warning) and red (danger).
ProgressTone budgetRowTone(BudgetPeriod p) => switch (p.tone) {
  BudgetTone.danger => ProgressTone.danger,
  BudgetTone.warning => ProgressTone.warning,
  BudgetTone.neutral => ProgressTone.normal,
};

/// How far [today] is through a period, 0..1 (the row's pace tick); null for
/// an open-ended or empty period.
double? budgetPaceFraction(DateTime start, DateTime? end, DateTime today) {
  if (end == null) return null;
  final total = end.difference(start).inHours;
  if (total <= 0) return null;
  final elapsed = today.difference(start).inHours;
  return (elapsed / total).clamp(0.0, 1.0);
}

/// An amount for a row: the user's currency, no decimals when whole.
String budgetRowMoney(BuildContext context, num amount) {
  final symbol = context.readUserCurrencySymbol;
  if (isMoneyHidden(context)) return moneyString(context, amount);
  final whole = amount == amount.roundToDouble();
  return CurrencyFormatter.format(
    amount,
    symbol: symbol,
    decimalDigits: whole ? 0 : null,
  );
}

/// What the budget counts, in one line ("Buffet + sub · Tags: เที่ยว"); null
/// when nothing is picked. [all] = "Every expense".
String? budgetScopeSummary(
  AppLocalizations l, {
  required bool all,
  required List<BudgetScopeCategory> categories,
  required List<String> tags,
  required List<AccountRef> wallets,
}) {
  if (all) return l.bgScopeAll;
  final parts = [
    if (categories.isNotEmpty)
      categories
          .map(
            (c) => c.includeChildren
                ? '${c.category.name} ${l.bgScopeChildren}'
                : c.category.name,
          )
          .join(', '),
    if (tags.isNotEmpty) '${l.bgScopeTags}: ${tags.join(', ')}',
    if (wallets.isNotEmpty)
      '${l.bgScopeWallets}: ${wallets.map((w) => w.name).join(', ')}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Why a counted row counts ("Counted because: category Buffet"), from the
/// BE's `reason`; null when it has none.
String? budgetReasonText(AppLocalizations l, Budget b, BudgetItem i) {
  switch (i.reason) {
    case BudgetReason.all:
      return l.fpBudgetsReasonAll;
    case BudgetReason.category:
      final c = i.category?.name;
      return c == null ? null : l.fpBudgetsReasonCategory(c);
    case BudgetReason.subCategory:
      final parent = i.category?.parentId;
      final scope = b.scope.categories
          .where((s) => s.category.id == parent)
          .firstOrNull;
      return scope == null
          ? l.fpBudgetsReasonSubCategoryAny
          : l.fpBudgetsReasonSubCategory(scope.category.name);
    case BudgetReason.tag:
      final tag = i.tags.where(b.scope.tags.contains).firstOrNull;
      return tag == null ? null : l.fpBudgetsReasonTag(tag);
    case BudgetReason.wallet:
      final w = i.account?.name;
      return w == null ? null : l.fpBudgetsReasonWallet(w);
    case BudgetReason.none:
      return null;
  }
}

/// "รายปี · เหลือ 77 วัน": the period kind and the days left.
String budgetRowCaption(BuildContext context, AppLocalizations l, Budget b) {
  final kind = b.recurring && b.rule != null
      ? budgetRuleLabel(l, b.rule!)
      : (b.period.end == null ? l.bgRowOpenEnded : l.bgRowOneOff);
  final left = b.period.daysLeft;
  return [
    kind,
    if (left != null && b.state == BudgetState.active) l.bgRowDaysLeft(left),
  ].join(' · ');
}
