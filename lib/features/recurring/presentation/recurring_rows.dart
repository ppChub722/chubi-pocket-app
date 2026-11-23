import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import '../domain/recurring.dart';
import '../domain/recurring_item.dart';

String recurringKindLabel(AppLocalizations l, RecurringKind k) => switch (k) {
  RecurringKind.expense => l.fpRecurringKindExpense,
  RecurringKind.income => l.fpRecurringKindIncome,
  RecurringKind.transfer => l.fpRecurringKindTransfer,
  RecurringKind.saving => l.fpRecurringKindSaving,
  RecurringKind.debt => l.fpRecurringKindDebt,
};

IconData recurringKindIcon(RecurringKind k) => k.iconDefault.icon;

/// Each kind's own icon + colour, shown when the item has neither its own
/// icon nor a category.
extension RecurringKindIconDefault on RecurringKind {
  TypeIconDefault get iconDefault => switch (this) {
    RecurringKind.expense => const TypeIconDefault(
      iconId: 'subscriptions',
      color: ModuleColors.defaultSubscription,
    ),
    RecurringKind.income => const TypeIconDefault(
      iconId: 'cash',
      color: ModuleColors.defaultIncome,
    ),
    RecurringKind.transfer => const TypeIconDefault(
      iconId: 'swap_horiz',
      color: ModuleColors.defaultReminder,
    ),
    RecurringKind.saving => const TypeIconDefault(
      iconId: 'savings',
      color: ModuleColors.defaultSaving,
    ),
    RecurringKind.debt => const TypeIconDefault(
      iconId: 'handshake',
      color: ModuleColors.defaultDebt,
    ),
  };
}

/// What a recurring item shows: its own icon, else its category's, else its
/// kind's.
PpForgeIconCode recurringIconCode({
  required RecurringKind kind,
  PpForgeIconCode? own,
  PpForgeIconCode? category,
}) => (own ?? category).orDefault(kind.iconDefault);

extension RecurringShownIcon on Recurring {
  PpForgeIconCode get shownIconCode => recurringIconCode(
    kind: kind,
    own: iconCode,
    category: category?.iconCode,
  );
}

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
    // 0.4.3: an item with 2+ lines shows "N รายการ" and this month's total.
    final many = r.linesCount > 1;
    final shown = amount ?? (many ? r.monthTotal : r.amount);
    final known = shown != null && shown > 0;
    final account = many ? null : r.account;
    final planCount = r.planCount;
    final icon = r.shownIconCode;
    return PpForgeListRow(
      // The item's own colour for what the row holds (the footer's chain).
      accent: icon.accentColorFor(
        Theme.of(context).extension<PpForgeColors>()!,
      ),
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
        parts: [
          recurringKindLabel(l, r.kind),
          many
              ? l.recurringLinesCount(r.linesCount)
              : recurrenceLabel(l, r.rule),
          r.autoCreate ? l.recurringTagAuto : l.recurringTagRemind,
          if (!many && r.paidBy != null) l.recurringLinePaidBy(r.paidBy!.name),
          // หนี้: with whom, จดหนี้ | จ่ายหนี้.
          if (r.isDebt)
            ...debtParts(
              l,
              person: r.counterparty?.name ?? r.person?.name,
              sub: many ? null : r.debtSub,
            ),
        ],
        glyphs: [
          if (planCount != null)
            ListRowGlyph(
              AppIcons.progress,
              text: '${r.planDone ?? 0}/$planCount',
            )
          else if (r.progressTotal != null)
            ListRowGlyph(
              AppIcons.progress,
              text: '${r.progressDone}/${r.progressTotal}',
            ),
        ],
      ),
      // No amount yet (a bill): nothing on the right.
      trailing: known
          ? ListRowTrailing.value(
              MoneyText(
                signedOf(r.type, shown, saving: r.isSaving),
                tone: toneOf(r.type, saving: r.isSaving),
              ),
            )
          : null,
      footer: footer,
      dimmed: r.status != RecurringStatus.active,
      onTap: onTap,
    );
  }

  static ListRowChip? _status(AppLocalizations l, Recurring r) =>
      switch (r.status) {
        _ when r.isComplete => ListRowChip(
          l.recurringStatusDone,
          tone: Tone.success,
        ),
        // หนี้ with nothing owed 3 rounds (K13): it starts again by itself.
        RecurringStatus.paused
            when r.pauseReason == RecurringPauseReason.noBalance =>
          ListRowChip(
            l.recurringNoBalanceChip,
            tone: Tone.warning,
            icon: AppIcons.pause,
          ),
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

/// A หนี้ row's bits for its second line: the person, then จดหนี้ |
/// จ่ายหนี้ (either may be missing).
List<String> debtParts(
  AppLocalizations l, {
  required String? person,
  required DebtEntrySub? sub,
}) => [
  if (person != null && person.trim().isNotEmpty) person.trim(),
  if (sub != null)
    sub == DebtEntrySub.repay ? l.debtSettleChip : l.debtRecordChip,
];

/// A due row's pill for why its rule stopped by itself: ค้าง 3 งวด (R7) or
/// ไม่มียอดค้าง (หนี้, K13); null otherwise.
ListRowChip? pauseReasonChip(AppLocalizations l, RecurringPauseReason? r) =>
    switch (r) {
      RecurringPauseReason.overdueLimit => ListRowChip(
        l.recurringOverdueLimitChip,
        tone: Tone.warning,
      ),
      RecurringPauseReason.noBalance => ListRowChip(
        l.recurringNoBalanceChip,
        tone: Tone.warning,
      ),
      _ => null,
    };

/// [debtParts] of an occurrence; empty for one that isn't หนี้.
List<String> occurrenceDebtParts(AppLocalizations l, RecurringItem i) =>
    i.isDebt ? debtParts(l, person: i.person?.name, sub: i.debtSub) : const [];

/// ออมเงิน ([saving]) stays plain: the money moves to a goal, it isn't spent.
num signedOf(TransactionType type, double amount, {bool saving = false}) =>
    !saving && type == TransactionType.expense ? -amount : amount;

MoneyTone toneOf(TransactionType type, {bool saving = false}) =>
    saving || type == TransactionType.transfer
    ? MoneyTone.plain
    : MoneyTone.signed;

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
