import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_page.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../domain/rule_draft.dart';
import '../recurring_rows.dart' show toneOf;

/// What a rule row's ⋯ asks for.
enum RuleRowMenu { pause, resume, delete }

/// One rule, the same row on every page (mock DetailNew sticky "Rules",
/// AutoBox, WalletKbank): its category's icon | ↻ the repeat + the type chip |
/// wallet · category · 🔔 (notify) · ⚡ (auto) | tags | the amount with
/// ยืนยันเอง / อัตโนมัติ, or รอใส่ยอด when asked. A paused rule is dimmed with
/// a พัก chip. No "Rule n" label (the list order is it). [title] = the
/// recurring's name on another page (Netflix · rule 1 จาก 2).
class RuleRow extends StatelessWidget {
  const RuleRow({
    required this.draft,
    this.line,
    this.title,
    this.subtitle,
    this.onTap,
    this.onMenu,
    super.key,
  });

  /// A saved rule's row.
  factory RuleRow.of(
    RecurringLine line, {
    String? title,
    String? subtitle,
    VoidCallback? onTap,
    ValueChanged<RuleRowMenu>? onMenu,
    Key? key,
  }) => RuleRow(
    key: key,
    draft: RuleDraft.fromLine(line),
    line: line,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    onMenu: onMenu,
  );

  final RuleDraft draft;
  final RecurringLine? line;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final ValueChanged<RuleRowMenu>? onMenu;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = draft;
    final paused = line?.status == RecurringStatus.paused;
    final asked = d.ask && d.canAsk;
    final notifyOn = d.notify ?? line?.notifyOn ?? true;
    final autoOn = !asked && (d.autoAccept ?? line?.autoAcceptOn ?? false);
    final type = d.type == RecurringKind.saving
        ? TransactionType.transfer
        : d.type.defaultType;
    final color = txWordsColor(
      context,
      type,
      debt: d.type == RecurringKind.debt && d.debtRecord,
      repay: d.type == RecurringKind.debt && !d.debtRecord,
    );
    final wallet = d.paidBy != null
        ? ListRowChip(d.paidBy!.name, icon: AppIcons.contact, bare: true)
        : d.account == null
        ? null
        : walletRowChip(
            context,
            name: d.account!.name,
            iconCode: d.account!.iconCode,
            type: d.account!.type,
          );
    final where = switch (d.type) {
      RecurringKind.transfer => d.toAccount?.name,
      RecurringKind.saving => d.goal?.name,
      RecurringKind.debt => d.planName ?? d.institution?.name ?? d.person?.name,
      _ => d.category?.name,
    };
    final amount = line?.amount ?? d.amount;
    final repeat = recurrenceLabel(l, d.rule, compact: true);
    return PpForgeListRow(
      leading: IconDisplay(
        iconCode: d.category?.iconCode,
        type: IconType.category,
        size: 36,
      ),
      title: title ?? repeat,
      titleChips: [
        if (title == null) ListRowChip(_typeLabel(l, d.type), color: color),
      ],
      status: paused ? ListRowChip(l.ruleStatusPaused) : null,
      line2: ListRowLine(
        lead: title != null ? null : wallet,
        parts: [
          ?subtitle,
          if (title != null) repeat,
          if (title != null && wallet != null) wallet.label,
          ?where,
        ],
        glyphs: [
          if (notifyOn) const ListRowGlyph(AppIcons.notifications),
          if (autoOn) const ListRowGlyph(AppIcons.auto),
        ],
      ),
      line3: d.tags.isEmpty
          ? null
          : ListRowLine(
              spans: [
                for (final t in d.tags) ...[
                  tagSpan(context, t.name),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
      trailing: asked || amount == null || amount <= 0
          ? ListRowTrailing.text(
              l.ruleRowAsk,
              tone: Tone.warning,
              caption: l.ruleAmountAsk,
            )
          : ListRowTrailing.value(
              MoneyText(amount, tone: toneOf(type)),
              caption: autoOn ? l.ruleRowAuto : l.ruleRowManual,
            ),
      dimmed: paused,
      onTap: onTap,
      actions: [
        if (onMenu != null)
          ListRowAction.icon(
            AppIcons.more,
            tooltip: l.commonMore,
            onTap: () => _menu(context, l, paused),
          ),
      ],
    );
  }

  Future<void> _menu(
    BuildContext context,
    AppLocalizations l,
    bool paused,
  ) async {
    final picked = await showOptionSheet<RuleRowMenu>(
      context,
      title: l.commonMore,
      options: [
        if (paused)
          SheetOption(value: RuleRowMenu.resume, label: l.recurringResume)
        else
          SheetOption(value: RuleRowMenu.pause, label: l.recurringPause),
        SheetOption(value: RuleRowMenu.delete, label: l.ruleDelete),
      ],
    );
    if (picked != null) onMenu?.call(picked);
  }

  static String _typeLabel(AppLocalizations l, RecurringKind k) => switch (k) {
    RecurringKind.expense => l.ruleTypeExpense,
    RecurringKind.income => l.ruleTypeIncome,
    RecurringKind.transfer => l.ruleTypeTransfer,
    RecurringKind.saving => l.ruleTypeSaving,
    RecurringKind.debt => l.ruleTypeDebt,
  };
}
