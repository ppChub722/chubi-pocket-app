import 'package:flutter/material.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/budget.dart';
import '../domain/budget_detail.dart';
import '../domain/budget_period.dart';
import 'budget_labels.dart';

// Thin wrappers: BE-computed figures → kit pieces. No client-side maths
// beyond bar ratios (the BE sends every amount, %, status and forecast).

/// The hero's footer: used (big) · "จาก … · เหลือ …" · the bar with its legend.
Widget budgetHeroStats(BuildContext context, Budget b, BudgetPeriod p) {
  final l = AppLocalizations.of(context)!;
  return ProgressHeroFooter(
    caption: l.bgHeroUsed,
    amount: p.used,
    subCaption: [
      l.bgHeroOfLimit(moneyString(context, p.amount)),
      if (p.overBy > 0)
        l.bgHeroOver(moneyString(context, p.overBy))
      else
        l.bgHeroRemaining(moneyString(context, p.remaining)),
    ].join(' · '),
    value: p.usedRatio,
    expected: p.expected > 0 ? p.expectedRatio : null,
    tone: budgetProgressTone(p),
    color: budgetTint(context, b),
    legendUsed: l.bgLegendUsed(p.pct),
    legendExpected: p.expected > 0
        ? l.bgLegendExpected(moneyString(context, p.expected))
        : null,
  );
}

/// The view-mode sections of the budget page, in order: the period's own
/// amount (recurring) · ภาพรวม · แยกตามที่มา · แยกตามหมวดหมู่ · รอบงบ ·
/// รายการ. A section with nothing to show returns null.
List<Widget? Function(bool)> budgetViewSections(
  BuildContext context, {
  required BudgetDetail detail,
  required BudgetPeriodPage? allPeriods,
  required bool editingLocked,
  required bool moreBusy,
  required Object? moreError,
  required VoidCallback onEditPeriod,
  required ValueChanged<BudgetPeriod> onOpenPeriod,
  required VoidCallback onMoreItems,
  required VoidCallback onMorePeriods,
}) {
  final l = AppLocalizations.of(context)!;
  final b = detail.budget;
  final p = b.period;
  final f = detail.forecast;
  final tint = budgetTint(context, b);

  return [
    // The period's own amount / note — recurring budgets only (headless: it
    // joins the page's top box).
    (first) => !b.recurring
        ? null
        : SectionCard(
            first: first,
            children: [
              DetailRow.pick(
                label: l.bgPeriodAmountField,
                value: moneyString(context, p.amount),
                helper: p.overridden
                    ? l.bgPeriodUseBase(moneyString(context, p.baseAmount))
                    : null,
                emptyText: l.quickEventNone,
                onTap: b.actions.edit ? onEditPeriod : null,
              ),
              if ((p.note ?? '').isNotEmpty)
                DetailStacked(
                  label: l.commonNote,
                  child: AppText(p.note!, role: AppTextRole.body),
                ),
            ],
          ),
    // ภาพรวม
    (first) {
      final tiles = <Widget>[
        if (f.dailyAllowance != null)
          StatTile(
            caption: l.bgTileAllowance,
            value: moneyString(context, f.dailyAllowance!),
            subCaption: l.bgTileAllowanceSub,
          ),
        if (f.forecastOverDate != null)
          StatTile(
            caption: l.bgTilePaceOver,
            value: budgetDate(context, f.forecastOverDate!),
            subCaption: f.avgDaily == null
                ? null
                : l.bgTilePaceAvg(moneyString(context, f.avgDaily!)),
            tone: Tone.warning,
          )
        else if (f.avgDaily != null)
          StatTile(
            caption: l.bgTilePaceOk,
            value: moneyString(context, f.avgDaily!),
            subCaption: l.bgTilePaceAvg(moneyString(context, f.avgDaily!)),
          ),
        if (f.forecastEnd != null)
          StatTile(
            caption: l.bgTileForecastEnd,
            value: moneyString(context, f.forecastEnd!),
            subCaption: (f.forecastOverBy ?? 0) > 0
                ? l.bgTileForecastOver(moneyString(context, f.forecastOverBy!))
                : null,
            tone: (f.forecastOverBy ?? 0) > 0 ? Tone.warning : Tone.neutral,
          ),
        if (f.avgMonthly != null)
          StatTile(
            caption: l.bgTileAvgMonthly,
            value: moneyString(context, f.avgMonthly!),
          ),
        if (f.thisMonth != null)
          StatTile(
            caption: l.bgTileThisMonth,
            value: moneyString(context, f.thisMonth!),
          ),
        if (p.expected > 0)
          StatTile(
            caption: l.bgTileRemainingAfter,
            value: moneyString(context, f.remainingAfterExpected),
          ),
        if (f.historyAvg != null && f.historyCount > 0)
          StatTile(
            caption: l.bgTileHistoryAvg(f.historyCount),
            value: moneyString(context, f.historyAvg!),
            subCaption: l.bgTilePerPeriod,
          ),
      ];
      if (tiles.isEmpty) return null;
      return SectionCard(
        first: first,
        title: l.bgSectionOverview,
        description: f.elapsedDays != null && f.totalDays != null
            ? l.bgOverviewDays(f.elapsedDays!, f.totalDays!)
            : null,
        fields: true,
        children: [StatGrid(children: tiles)],
      );
    },
    // แยกตามที่มา
    (first) => detail.bySource.isEmpty
        ? null
        : SectionCard(
            first: first,
            title: l.bgSectionSource,
            children: [
              for (final s in detail.bySource)
                BreakdownRow(
                  label: budgetSourceLabel(l, s.source),
                  caption: l.bgSourceCount(s.count),
                  amount: s.amount,
                  expected: s.expected,
                  value: p.amount <= 0 ? null : s.amount / p.amount,
                  color: tint,
                ),
            ],
          ),
    // แยกตามหมวดหมู่
    (first) => detail.byCategory.isEmpty
        ? null
        : SectionCard(
            first: first,
            title: l.bgSectionCategory,
            children: [
              for (final c in detail.byCategory)
                BreakdownRow(
                  leading: IconDisplay(
                    type: IconType.category,
                    size: 28,
                    iconCode: c.category?.iconCode,
                  ),
                  label: c.category?.name ?? l.bgNoCategory,
                  amount: c.amount,
                  value: c.pct / 100,
                  color: tint,
                ),
            ],
          ),
    // รอบงบ
    (first) {
      if (!b.recurring) return null;
      final periods = allPeriods?.periods ?? detail.periods.periods;
      if (periods.isEmpty) return null;
      final more = allPeriods == null
          ? detail.periods.hasMore
          : allPeriods.hasMore;
      return SectionCard(
        first: first,
        title: l.bgSectionPeriods,
        description: l.bgPeriodsDescription,
        children: [
          for (final x in periods)
            ProgressCard.compact(
              title: budgetPeriodTitle(context, b, x),
              badge: _periodBadges(l, b, x),
              value: x.usedRatio,
              expected: x.expected > 0 ? x.expectedRatio : null,
              tone: budgetProgressTone(x),
              label: l.bgRowUsed(
                moneyString(context, x.used),
                moneyString(context, x.amount),
              ),
              struckLabel: x.overridden && x.amount != x.baseAmount
                  ? moneyString(context, x.baseAmount)
                  : null,
              percentText: '${x.pct}%',
              onTap: x.id == p.id ? null : () => onOpenPeriod(x),
            ),
          if (more)
            DetailRow.pick(
              label: l.bgPeriodsAll,
              emptyText: l.quickEventNone,
              onTap: moreBusy ? null : onMorePeriods,
            ),
        ],
      );
    },
    // รายการ
    (first) => SectionCard(
      first: first,
      title: l.bgSectionItems,
      description: l.bgItemsDescription,
      children: [
        if (detail.items.items.isEmpty)
          EmptyView.compact(message: l.bgItemsEmpty)
        else
          for (final i in detail.items.items) _itemRow(context, l, i),
        if (detail.items.hasMore)
          DetailRow.pick(
            label: l.bgItemsMore,
            emptyText: l.quickEventNone,
            error: moreError == null ? null : '$moreError',
            onTap: moreBusy ? null : onMoreItems,
          ),
      ],
    ),
  ];
}

Widget _itemRow(BuildContext context, AppLocalizations l, BudgetItem i) {
  final title = (i.description ?? '').isNotEmpty
      ? i.description!
      : (i.category?.name ?? i.event?.name ?? '—');
  return TxRow(
    leading: IconDisplay(
      type: IconType.category,
      size: 36,
      iconCode: i.category?.iconCode ?? i.event?.iconCode,
    ),
    title: title,
    amount: -i.amount,
    walletLabel: i.account?.name,
    walletIcon: i.account == null
        ? null
        : IconDisplay(
            type: IconType.account,
            size: 14,
            iconCode: i.account!.iconCode,
          ),
    source: AppChip(
      label: i.event != null && i.source == BudgetSource.event
          ? '${l.bgSourceEvent} ${i.event!.name}'
          : budgetSourceLabel(l, i.source),
      size: ChipSize.mini,
      tone: AppChipTone.neutral,
    ),
    category: i.category != null && i.category!.name != title
        ? i.category!.name
        : null,
    extra: i.date == null ? null : budgetDate(context, i.date!),
    recurring: i.recurringItemId != null,
    progress: i.recurringSeq == null
        ? null
        : (i.recurringTotal == null
              ? '${i.recurringSeq}'
              : '${i.recurringSeq}/${i.recurringTotal}'),
    dimmed: i.expected,
    onTap: i.kind == 'transaction'
        ? () => openPage(context, '/transactions/${i.id}')
        : null,
  );
}

/// A period row's badges: this period · set for this period only · status.
Widget? _periodBadges(AppLocalizations l, Budget b, BudgetPeriod x) {
  final status = x.isCurrent
      ? null
      : budgetStatusChip(l, b, period: x, size: ChipSize.mini);
  if (!x.isCurrent && !x.overridden && status == null) return null;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (x.isCurrent)
        AppChip(
          label: l.bgPeriodNow,
          size: ChipSize.mini,
          selected: true,
          tone: AppChipTone.neutral,
        ),
      if (x.overridden) ...[
        if (x.isCurrent) const SizedBox(width: AppSpacing.xs),
        AppChip(
          label: l.bgPeriodOverridden,
          size: ChipSize.mini,
          selected: true,
          tone: AppChipTone.info,
        ),
      ],
      if (status != null) ...[const SizedBox(width: AppSpacing.xs), status],
    ],
  );
}
