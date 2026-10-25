import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurring.dart';

String recurringKindLabel(AppLocalizations l, RecurringKind k) => switch (k) {
  RecurringKind.subscription => l.fpRecurringKindSubscription,
  RecurringKind.installment => l.fpRecurringKindInstallment,
  RecurringKind.income => l.fpRecurringKindIncome,
  RecurringKind.reminder => l.fpRecurringKindReminder,
};

IconData recurringKindIcon(RecurringKind k) => switch (k) {
  RecurringKind.subscription => AppIcons.subscription,
  RecurringKind.installment => AppIcons.progress,
  RecurringKind.income => AppIcons.cash,
  RecurringKind.reminder => AppIcons.notifications,
};

class RecurringRow extends StatelessWidget {
  const RecurringRow({
    required this.recurring,
    this.amount,
    this.footer,
    this.onTap,
    super.key,
  });

  final Recurring recurring;

  final double? amount;

  /// Under the name and amount (an installment's chain).
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final r = recurring;
    final next = r.nextDate;
    final shown = amount ?? r.amount;
    final known = shown != null && shown > 0;
    final account = r.account;
    final icon = r.iconCode ?? r.category?.iconCode;
    return AppListRow(
      // The item's own colour for what the row holds (the footer's chain).
      accent: icon?.accentColorFor(Theme.of(context).extension<AppColors>()!),
      leading: IconDisplay(type: IconType.category, size: 36, iconCode: icon),
      title: r.name,
      // Its state (พัก / ใกล้ครบ) or when it is next ("อีก 3 วัน") beside the
      // name; the wallet leads line 2 so the name keeps its room.
      status:
          _status(l, r) ??
          (next == null
              ? null
              : ListRowChip(
                  dueLabel(
                    l,
                    date: next,
                    daysUntil: r.daysUntil,
                    withDate: false,
                  ),
                  tone: (r.daysUntil ?? 0) < 0 ? Tone.warning : Tone.primary,
                )),
      line2: ListRowLine(
        lead: account == null
            ? null
            : walletRowChip(
                context,
                name: account.name,
                iconCode: account.iconCode,
                type: account.type,
              ),
        icon: AppIcons.recurring,
        parts: [recurrenceLabel(l, r.rule)],
        glyphs: [
          if (r.progressTotal != null)
            ListRowGlyph(
              AppIcons.progress,
              text: '${r.progressDone}/${r.progressTotal}',
            ),
        ],
      ),
      // No amount yet (a bill): nothing on the right.
      trailing: known
          ? ListRowTrailing.value(
              MoneyText(signedOf(r.type, shown), tone: toneOf(r.type)),
            )
          : null,
      footer: footer,
      dimmed: r.status != RecurringStatus.active,
      onTap: onTap,
    );
  }

  static ListRowChip? _status(AppLocalizations l, Recurring r) =>
      switch (r.status) {
        RecurringStatus.paused => ListRowChip(
          l.recurringStatusPaused,
          tone: Tone.warning,
          icon: AppIcons.pause,
        ),
        RecurringStatus.archived => ListRowChip(l.recurringStatusArchived),
        RecurringStatus.active when r.endingSoon => ListRowChip(
          l.recurringStatusEndingSoon,
          tone: Tone.warning,
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

/// An occurrence's wallet as the list rows' wallet chip, by its name.
ListRowChip? occurrenceWalletChip(BuildContext context, AccountRef? account) =>
    account == null
    ? null
    : walletRowChip(
        context,
        name: account.name,
        iconCode: account.iconCode,
        type: account.type,
      );

/// A waiting occurrence's pill: รอใส่ยอด / รอยืนยัน in warning.
ListRowChip waitingChip(String label) =>
    ListRowChip(label, tone: Tone.warning, selected: true);

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
