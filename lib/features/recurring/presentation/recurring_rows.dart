import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

// Thin wrappers: models → the kit's TxRow (no styling here).

/// The kind's label ("ค่าสมาชิก", "ผ่อนชำระ", "รายรับ", "เตือนจ่าย").
String recurringKindLabel(AppLocalizations l, RecurringKind k) => switch (k) {
  RecurringKind.subscription => l.fpRecurringKindSubscription,
  RecurringKind.installment => l.fpRecurringKindInstallment,
  RecurringKind.income => l.fpRecurringKindIncome,
  RecurringKind.reminder => l.fpRecurringKindReminder,
};

/// One recurring setting in a list: icon · name · wallet chip | amount (or
/// "รอยอด" while a reminder has none); line 2 = next due · rule (· n/N).
class RecurringRow extends StatelessWidget {
  const RecurringRow({
    required this.recurring,
    this.amount,
    this.onTap,
    super.key,
  });

  final Recurring recurring;

  /// The amount to show; defaults to the setting's own. A reminder tab passes
  /// the next occurrence's.
  final double? amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final r = recurring;
    final next = r.nextDate;
    final shown = amount ?? r.amount;
    final known = shown != null && shown > 0;
    return TxRow(
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: r.iconCode ?? r.category?.iconCode,
      ),
      title: r.name,
      amount: known ? signedOf(r.type, shown) : 0,
      amountText: known ? null : l.fpRecurringAwaitingAmount,
      tone: toneOf(r.type),
      walletLabel: r.account?.name,
      walletIcon: r.account == null
          ? null
          : IconDisplay(
              type: IconType.account,
              size: 14,
              iconCode: r.account!.iconCode,
            ),
      statusChip: _status(l, r),
      dimmed: r.status != RecurringStatus.active,
      recurring: true,
      progress: r.progressTotal == null
          ? null
          : '${r.progressDone}/${r.progressTotal}',
      metaLeading: next == null
          ? null
          : DueText(date: next, daysUntil: r.daysUntil, withDate: false),
      meta: [recurrenceLabel(l, r.rule)],
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
    this.onLongPress,
    super.key,
  });

  final RecurringItem item;

  /// Name the recurring it came from (a mixed list).
  final bool showParent;
  final bool showState;

  /// A `SelectCheck` in bulk mode.
  final Widget? select;
  final VoidCallback? onTap;

  /// Enters bulk-select (long-press).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final i = item;
    final parent = showParent ? i.recurring?.name : null;
    final title = i.title;
    final progress = i.seq == null
        ? null
        : (i.total == null ? '${i.seq}' : '${i.seq}/${i.total}');
    final known = i.amount != null && i.amount! > 0;
    final row = TxRow(
      leading: IconDisplay(
        type: IconType.category,
        size: 36,
        iconCode: i.category?.iconCode ?? i.recurring?.iconCode,
      ),
      title: title.isEmpty ? (i.category?.name ?? '—') : title,
      amount: known ? signedOf(i.type, i.amount!) : 0,
      amountText: known ? null : l.fpRecurringAwaitingAmount,
      tone: toneOf(i.type),
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
        if (i.category != null && i.category!.name != title) i.category!.name,
      ].join(' · '),
      select: select,
      onTap: onTap,
    );
    if (onLongPress == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: row,
    );
  }
}

/// Expense shows negative, income positive, a transfer unsigned.
num signedOf(TransactionType type, double amount) =>
    type == TransactionType.expense ? -amount : amount;

MoneyTone toneOf(TransactionType type) =>
    type == TransactionType.transfer ? MoneyTone.plain : MoneyTone.signed;

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
