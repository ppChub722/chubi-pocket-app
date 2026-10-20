import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/refs.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';
import '../domain/budget_period.dart';

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

String budgetDate(BuildContext context, DateTime d) => _day(context, d);

String budgetRange(BuildContext context, DateTime start, DateTime? end) {
  final l = AppLocalizations.of(context)!;
  if (end == null) return l.bgRowSince(_day(context, start));
  return l.bgRowRange(_day(context, start), _day(context, end));
}

/// "1–31 ต.ค. 2026", "28 ต.ค. – 3 พ.ย. 2026": a range in a chip's room,
/// the month and year said once where the two days share them.
String budgetRangeShort(BuildContext context, DateTime start, DateTime end) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final last = DateFormat.yMMMd(locale).format(end);
  if (start.year != end.year) return '${_day(context, start)} – $last';
  final dayFirst = DateFormat.MMMd(locale).pattern?.startsWith('d') ?? false;
  if (start.month == end.month && dayFirst) {
    return '${DateFormat.d(locale).format(start)}–$last';
  }
  return '${DateFormat.MMMd(locale).format(start)} – $last';
}

/// The first period's last day, worked out like the BE's periods: the next
/// start keeps the start's day (a short month uses its last day), less a day.
DateTime budgetFirstPeriodEnd(BudgetRule rule, DateTime start) {
  final n = rule.interval < 1 ? 1 : rule.interval;
  DateTime on(int y, int m, int d) {
    final last = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, d > last ? last : d);
  }

  final next = switch (rule.freq) {
    'daily' => DateTime(start.year, start.month, start.day + n),
    'weekly' => DateTime(start.year, start.month, start.day + 7 * n),
    'yearly' => on(start.year + n, start.month, start.day),
    _ => on(start.year, start.month + n, start.day),
  };
  return DateTime(next.year, next.month, next.day - 1);
}

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

String budgetSourceLabel(AppLocalizations l, BudgetSource s) => switch (s) {
  BudgetSource.normal => l.bgSourceNormal,
  BudgetSource.recurring => l.bgSourceRecurring,
  BudgetSource.event => l.bgSourceEvent,
  BudgetSource.upcoming => l.bgSourceUpcoming,
  BudgetSource.pending => l.bgSourcePending,
  BudgetSource.futureTx => l.bgSourceFutureTx,
};

/// The kit tone of a period: the BE's tone, never derived from the ratio.
ProgressTone budgetProgressTone(BudgetPeriod p) => switch (p.tone) {
  BudgetTone.danger => ProgressTone.danger,
  BudgetTone.warning => ProgressTone.warning,
  BudgetTone.neutral => ProgressTone.neutral,
};

Color budgetTint(BuildContext context, Budget budget) =>
    budget.iconCode.tintFor(Theme.of(context).extension<AppColors>()!);

Color budgetToneColor(BuildContext context, Budget budget, BudgetPeriod p) =>
    budgetProgressTone(
      p,
    ).resolve(context, entityTint: budgetTint(context, budget));

ProgressTone budgetRowTone(BudgetPeriod p) => switch (p.tone) {
  BudgetTone.danger => ProgressTone.danger,
  BudgetTone.warning => ProgressTone.warning,
  BudgetTone.neutral => ProgressTone.normal,
};

double? budgetPaceFraction(DateTime start, DateTime? end, DateTime today) {
  if (end == null) return null;
  final total = end.difference(start).inHours;
  if (total <= 0) return null;
  final elapsed = today.difference(start).inHours;
  return (elapsed / total).clamp(0.0, 1.0);
}

String budgetRowMoney(BuildContext context, num amount) =>
    moneyString(context, amount, symbol: context.readUserCurrencySymbol);

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
                ? l.bgScopeChildren(c.category.name)
                : c.category.name,
          )
          .join(', '),
    if (tags.isNotEmpty) '${l.bgScopeTags}: ${tags.join(', ')}',
    if (wallets.isNotEmpty)
      '${l.bgScopeWallets}: ${wallets.map((w) => w.name).join(', ')}',
  ];
  return parts.isEmpty ? null : parts.join(' | ');
}

String budgetRowCaption(BuildContext context, AppLocalizations l, Budget b) {
  final kind = b.recurring && b.rule != null
      ? budgetRuleLabel(l, b.rule!)
      : (b.period.end == null ? l.bgRowOpenEnded : l.bgRowOneOff);
  final left = b.period.daysLeft;
  return [
    kind,
    if (left != null && b.state == BudgetState.active) l.bgRowDaysLeft(left),
  ].join(' | ');
}
