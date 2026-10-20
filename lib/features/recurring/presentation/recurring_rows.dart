import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurring.dart';

String recurringKindLabel(AppLocalizations l, RecurringKind k) => switch (k) {
  RecurringKind.subscription => l.fpRecurringKindSubscription,
  RecurringKind.installment => l.fpRecurringKindInstallment,
  RecurringKind.income => l.fpRecurringKindIncome,
  RecurringKind.reminder => l.fpRecurringKindReminder,
};

class RecurringRow extends StatelessWidget {
  const RecurringRow({
    required this.recurring,
    this.amount,
    this.onTap,
    super.key,
  });

  final Recurring recurring;

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

/// A rule with an end, one dot per occurrence (the BE's `chain`, else from
/// its progress), the next one marked; null for a rule with no end.
List<ChainDot>? endChainDots(Recurring r) {
  ChainDot dot(OccurrenceState s) => switch (s) {
    OccurrenceState.done || OccurrenceState.paid => ChainDot.paid,
    OccurrenceState.notCreated || OccurrenceState.pending => ChainDot.wait,
    OccurrenceState.archived => ChainDot.skipped,
    OccurrenceState.upcoming => ChainDot.future,
  };
  final chain = r.chain;
  final total = r.progressTotal;
  final dots = chain != null && chain.isNotEmpty
      ? [for (final c in chain) dot(c.state)]
      : total != null && total > 0
      ? [
          for (var i = 0; i < total; i++)
            i < r.progressDone ? ChainDot.paid : ChainDot.future,
        ]
      : null;
  if (dots == null) return null;
  final next = dots.indexOf(ChainDot.future);
  if (next >= 0) dots[next] = ChainDot.current;
  return dots;
}

num signedOf(TransactionType type, double amount) =>
    type == TransactionType.expense ? -amount : amount;

MoneyTone toneOf(TransactionType type) =>
    type == TransactionType.transfer ? MoneyTone.plain : MoneyTone.signed;

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
