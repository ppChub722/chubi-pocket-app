import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/transaction_type.dart';
import '../../pending/domain/pending_transaction.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

// Thin wrappers: models → the kit's TxRow (no styling here).

/// One recurring setting in the management list: icon · name · wallet chip |
/// amount; line 2 = category · rule · next due (· n/N).
class RecurringRow extends StatelessWidget {
  const RecurringRow({required this.recurring, this.onTap, super.key});

  final Recurring recurring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final r = recurring;
    final next = r.nextDate;
    return TxRow(
      leading: r.isSaving
          ? savingLeading(context)
          : IconDisplay(
              type: IconType.category,
              size: 36,
              iconCode: r.iconCode ?? r.category?.iconCode,
            ),
      title: r.name,
      amount: signedOf(r.type, r.amount, saving: r.isSaving),
      tone: toneOf(r.type, saving: r.isSaving),
      walletLabel: r.account?.name,
      walletIcon: r.account == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: r.account!.iconCode,
            ),
      statusChip: _status(l, r),
      dimmed: r.status == RecurringStatus.archived,
      recurring: true,
      progress: r.progressTotal == null
          ? null
          : '${r.progressDone}/${r.progressTotal}',
      metaLeading: next == null
          ? null
          : DueText(date: next, daysUntil: r.daysUntil, withDate: false),
      meta: [
        if (r.isSaving) savingTargetLabel(l, r.goal),
        recurrenceLabel(l, r.rule),
      ],
      onTap: onTap,
    );
  }

  static Widget? _status(AppLocalizations l, Recurring r) => switch (r.status) {
    RecurringStatus.paused => StatusChip(
      label: l.recurringStatusPaused,
      kind: StatusKind.paused,
      size: ChipSize.mini,
    ),
    RecurringStatus.archived => StatusChip(
      label: l.recurringStatusArchived,
      kind: StatusKind.archived,
      size: ChipSize.mini,
    ),
    RecurringStatus.active when r.endingSoon => StatusChip(
      label: l.recurringStatusEndingSoon,
      kind: StatusKind.endingSoon,
      size: ChipSize.mini,
    ),
    _ => null,
  };
}

/// One item (produced / upcoming / manual): icon · title · wallet chip |
/// amount; line 2 = [recurring name ·] category (· n/N); its state chip.
class RecurringItemRow extends StatelessWidget {
  const RecurringItemRow({
    required this.item,
    this.showParent = false,
    this.showState = true,
    this.select,
    this.onTap,
    super.key,
  });

  final RecurringItem item;

  /// Name the recurring it came from (the all-upcoming list).
  final bool showParent;
  final bool showState;

  /// A `SelectCheck` in bulk mode.
  final Widget? select;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final parent = showParent ? i.recurring?.name : null;
    final title = i.title;
    final progress = i.seq == null
        ? null
        : (i.total == null ? '${i.seq}' : '${i.seq}/${i.total}');
    return TxRow(
      leading: i.isSaving
          ? savingLeading(context)
          : IconDisplay(
              type: IconType.category,
              size: 36,
              iconCode: i.category?.iconCode ?? i.recurring?.iconCode,
            ),
      title: title.isEmpty ? (i.category?.name ?? '—') : title,
      amount: signedOf(i.type, i.amount, saving: i.isSaving),
      tone: toneOf(i.type, saving: i.isSaving),
      walletLabel: i.account?.name,
      walletIcon: i.account == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: i.account!.iconCode,
            ),
      statusChip: showState
          ? OccurrenceStateChip(state: i.state, size: ChipSize.mini)
          : null,
      dimmed: i.state == OccurrenceState.archived,
      recurring: i.recurring != null,
      linked: i.linked,
      progress: progress,
      category: [
        if (parent != null && parent != title) parent,
        if (i.isSaving)
          savingTargetLabel(AppLocalizations.of(context)!, i.goal)
        else if (i.category != null && i.category!.name != title)
          i.category!.name,
      ].join(' · '),
      select: select,
      onTap: onTap,
    );
  }
}

/// Expense shows negative, income positive, a transfer / ออม unsigned.
num signedOf(TransactionType type, double amount, {bool saving = false}) =>
    !saving && type == TransactionType.expense ? -amount : amount;

MoneyTone toneOf(TransactionType type, {bool saving = false}) =>
    saving || type == TransactionType.transfer
    ? MoneyTone.plain
    : MoneyTone.signed;

/// The 🐷 tile of an ออม row.
Widget savingLeading(BuildContext context) => IconTile(
  icon: AppIcons.savingDeposit,
  color: Theme.of(context).colorScheme.primary,
  size: 36,
);

/// "→ เป้าหมาย X" / "→ ยังไม่จัดสรร".
String savingTargetLabel(AppLocalizations l, SavingGoalRef? goal) =>
    '→ ${goal?.name ?? l.savingEntrySpare}';

/// Items of one day, in list order.
class ItemDateGroup {
  const ItemDateGroup(this.date, this.items);

  final DateTime date;
  final List<RecurringItem> items;
}

/// Consecutive items grouped by date (the list is already sorted).
List<ItemDateGroup> groupItemsByDate(List<RecurringItem> items) {
  final out = <ItemDateGroup>[];
  for (final i in items) {
    if (out.isNotEmpty && out.last.date == i.date) {
      out.last.items.add(i);
    } else {
      out.add(ItemDateGroup(i.date, [i]));
    }
  }
  return out;
}

/// A day header: future days relative ("พรุ่งนี้", "อีก 3 วัน · 3 พ.ย."),
/// past days friendly ("วันนี้", "เมื่อวาน", "3 พ.ย.").
String itemDateLabel(BuildContext context, DateTime date) {
  final l = AppLocalizations.of(context)!;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date.isAfter(today)) return dueLabel(l, date: date);
  return DateFormatter.friendly(
    date,
    today: l.commonToday,
    yesterday: l.commonYesterday,
    locale: Localizations.localeOf(context).languageCode,
  );
}
