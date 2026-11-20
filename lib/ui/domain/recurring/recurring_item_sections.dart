import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/user_currency.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';
import '../../../features/personal_debts/domain/debt_direction.dart';
import '../../../features/recurring/domain/recurrence_rule.dart' show today;
import '../../../features/recurring/domain/recurring.dart';
import '../../../features/recurring/domain/recurring_page.dart';
import '../../../features/recurring/presentation/recurring_rows.dart';

/// What a line's menu asks for.
enum LineMenu { edit, pause, resume, archive, restore, delete }

/// The item page's บรรทัด section (2+ lines): each line as ↻ when · wallet
/// or คนจ่ายแทน · amount, its menu (pause / archive / delete), then + เพิ่ม
/// บรรทัด.
class RecurringLinesSection extends StatelessWidget {
  const RecurringLinesSection({
    required this.page,
    required this.onMenu,
    this.onAdd,
    super.key,
  });

  final RecurringPage page;
  final void Function(RecurringLine line, LineMenu action) onMenu;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = context.readUserCurrencySymbol;
    return SectionCard(
      key: const ValueKey('linesSection'),
      title: '${l.recurringLinesSection} | ${page.lines.length}',
      children: [
        for (final line in page.lines)
          OptionMenuAnchor<LineMenu>(
            options: [
              SheetOption(value: LineMenu.edit, label: l.commonEdit),
              if (line.actions.pause)
                SheetOption(value: LineMenu.pause, label: l.recurringPause),
              if (line.actions.resume)
                SheetOption(value: LineMenu.resume, label: l.recurringResume),
              if (line.actions.archive)
                SheetOption(value: LineMenu.archive, label: l.recurringArchive),
              if (line.actions.restore)
                SheetOption(value: LineMenu.restore, label: l.recurringRestore),
              if (line.actions.delete || page.lines.length > 1)
                SheetOption(value: LineMenu.delete, label: l.commonDelete),
            ],
            onSelected: (a) => onMenu(line, a),
            builder: (context, toggle) =>
                _row(context, l, line, symbol, onTap: toggle),
          ),
        if (onAdd != null)
          AddTile(
            key: const ValueKey('lineAdd'),
            label: l.recurringLineAdd,
            onTap: onAdd!,
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    RecurringLine line,
    String symbol, {
    VoidCallback? onTap,
  }) {
    final v = line.view;
    final amount = v.amount;
    final paidBy = line.paidBy;
    final status = switch (line.status) {
      RecurringStatus.paused => l.recurringStatusPaused,
      RecurringStatus.archived => l.recurringStatusArchived,
      RecurringStatus.done => l.recurringStatusDone,
      RecurringStatus.active => null,
    };
    return PpForgeListRow(
      key: ValueKey('line-${line.id}'),
      leading: const PpForgeAvatar.icon(AppIcons.recurring),
      title: recurrenceLabel(l, line.rule),
      line2: ListRowLine(
        lead: paidBy == null ? occurrenceWalletChip(context, v.account) : null,
        parts: [
          if (paidBy != null) l.recurringLinePaidBy(paidBy.name),
          if (v.debtSub != null)
            v.debtSub == DebtEntrySub.repay
                ? l.debtSettleChip
                : l.debtRecordChip,
          ?status,
        ],
      ),
      trailing: amount == null || amount <= 0
          ? ListRowTrailing.text(l.fpRecurringAwaitingValue)
          : ListRowTrailing.value(
              MoneyText(
                signedOf(v.type, amount, saving: v.isSaving),
                tone: toneOf(v.type, saving: v.isSaving),
                symbol: symbol,
              ),
            ),
      dimmed: line.status != RecurringStatus.active,
      onTap: onTap,
    );
  }
}

/// A debt item's plan on its page (paid / left / the last one are the
/// hero's tiles): เงินต้นคงเหลือ / ดอกที่ยังต้องจ่าย, the on-card note, and
/// ตารางงวด (tap an installment = แก้งวดนี้ / tick it).
class RecurringPlanSection extends StatelessWidget {
  const RecurringPlanSection({
    required this.plan,
    required this.onTable,
    super.key,
  });

  final RecurringPlan plan;
  final VoidCallback onTable;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    Widget tile(String label, String value) => SummaryTileView(
      tile: SummaryTile(label: label, value: value),
    );
    return SectionCard(
      key: const ValueKey('planView'),
      title: plan.closed
          ? '${l.recurringPlanSection} | ${l.recurringPlanClosed}'
          : l.recurringPlanSection,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (plan.hasInterest)
                HeroTiles(
                  joined: true,
                  children: [
                    tile(
                      l.recurringPlanLeftPrincipal,
                      money(plan.leftPrincipal),
                    ),
                    tile(l.recurringPlanLeftInterest, money(plan.leftInterest)),
                  ],
                ),
              if (plan.hasInterest && plan.onCard)
                const SizedBox(height: PpForgeSpacing.sm),
              if (plan.onCard)
                PpForgeMessage(message: l.recurringPlanOnCardNote),
              if (plan.hasInterest || plan.onCard)
                const SizedBox(height: PpForgeSpacing.sm),
            ],
          ),
        ),
        PpForgeDetailRow(
          key: const ValueKey('planTableRow'),
          label: l.recurringPlanTable,
          trailing: Text('${plan.done}/${plan.count}'),
          showChevron: true,
          onTap: onTable,
        ),
      ],
    );
  }
}

/// The plan's next installment for the hero: "งวดถัดไป (13/48) | อีก 12
/// วัน" and its amount; principal / interest go in the label when it has
/// interest.
String planNextLabel(
  AppLocalizations l,
  RecurringPlan plan,
  PlanInstallment next,
  String Function(double) money,
) {
  final days = next.dueDate.difference(today()).inDays;
  final when = dueLabel(l, date: next.dueDate, daysUntil: days);
  final head = l.recurringPlanNext(next.seq, plan.count, when);
  return next.interest > 0
      ? '$head | ${l.recurringPlanSplit(money(next.principal), money(next.interest))}'
      : head;
}

/// แก้งวดนี้: due date, amount, principal and interest of one installment;
/// null = cancelled.
Future<({DateTime? due, double? amount, double? principal, double? interest})?>
showInstallmentEditSheet(BuildContext context, PlanInstallment i) =>
    showPpForgeSheetCustom(
      context,
      builder: (_) => _InstallmentEdit(installment: i),
    );

class _InstallmentEdit extends StatefulWidget {
  const _InstallmentEdit({required this.installment});

  final PlanInstallment installment;

  @override
  State<_InstallmentEdit> createState() => _InstallmentEditState();
}

class _InstallmentEditState extends State<_InstallmentEdit> {
  late final _amount = TextEditingController(
    text: AmountInput.format(widget.installment.amount),
  );
  late final _principal = TextEditingController(
    text: AmountInput.format(widget.installment.principal),
  );
  late final _interest = TextEditingController(
    text: AmountInput.format(widget.installment.interest),
  );
  late DateTime _due = widget.installment.dueDate;

  @override
  void dispose() {
    _amount.dispose();
    _principal.dispose();
    _interest.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await PpForgeDatePicker.show(
      context,
      initial: _due,
      first: DateTime(_due.year - 2),
      last: DateTime(_due.year + 5, 12, 31),
    );
    if (picked is PpForgeDatePicked && mounted) {
      setState(() => _due = picked.date);
    }
  }

  void _save() {
    final i = widget.installment;
    double? changed(TextEditingController c, double was) {
      final v = AmountInput.parse(c.text);
      return v == null || v == was ? null : v;
    }

    Navigator.of(context).pop((
      due: _due == i.dueDate ? null : _due,
      amount: changed(_amount, i.amount),
      principal: changed(_principal, i.principal),
      interest: changed(_interest, i.interest),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    const money = TextInputType.numberWithOptions(decimal: true);
    return PickerSheet(
      title: l.recurringInstallmentEdit,
      subtitle: l.recurringInstallmentTitle(widget.installment.seq),
      footer: PpForgeButton(
        label: l.commonSave,
        expand: true,
        onPressed: _save,
      ),
      builder: (_, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PpForgeDetailRow(
            label: l.recurringInstallmentDueDate,
            trailing: Text(DateFormat.yMMMd(locale).format(_due)),
            showChevron: true,
            onTap: _pickDue,
          ),
          DetailTextField(
            label: l.recurringPlanInstallment,
            controller: _amount,
            editing: true,
            keyboardType: money,
          ),
          DetailTextField(
            label: l.recurringInstallmentPrincipal,
            controller: _principal,
            editing: true,
            keyboardType: money,
          ),
          DetailTextField(
            label: l.recurringInstallmentInterest,
            controller: _interest,
            editing: true,
            keyboardType: money,
          ),
        ],
      ),
    );
  }
}

/// ตารางงวด of a saved plan: every installment; a tap offers แก้งวดนี้ and
/// จ่ายงวดแล้ว / ยังไม่จ่าย.
Future<void> showPlanTable(
  BuildContext context,
  List<PlanInstallment> rows, {
  required ValueChanged<PlanInstallment> onPick,
}) => showInstallmentTable(context, rows, onTap: onPick);

/// The tap on one installment: what to do with it.
enum InstallmentMenu { edit, markPaid, unmark }

Future<InstallmentMenu?> showInstallmentMenu(
  BuildContext context,
  PlanInstallment i,
) {
  final l = AppLocalizations.of(context)!;
  return showChoiceDialog<InstallmentMenu>(
    context,
    title: l.recurringInstallmentTitle(i.seq),
    choices: [
      DialogChoice(
        value: InstallmentMenu.edit,
        label: l.recurringInstallmentEdit,
      ),
      if (i.paid)
        DialogChoice(
          value: InstallmentMenu.unmark,
          label: l.recurringInstallmentUnmark,
        )
      else
        DialogChoice(
          value: InstallmentMenu.markPaid,
          label: l.recurringInstallmentMarkPaid,
          variant: PpForgeButtonVariant.primary,
        ),
    ],
  );
}

/// ตารางงวด as a sheet: every installment with principal / interest.
Future<void> showInstallmentTable(
  BuildContext context,
  List<PlanInstallment> rows, {
  ValueChanged<PlanInstallment>? onTap,
}) {
  final l = AppLocalizations.of(context)!;
  return showPpForgeSheetCustom<void>(
    context,
    builder: (sheet) => PickerSheet(
      title: l.recurringPlanTable,
      subtitle: l.fpRecurringCountUnit(rows.length),
      builder: (_, _) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PpForgeSpacing.lg,
          0,
          PpForgeSpacing.lg,
          PpForgeSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final i in rows)
              installmentRow(
                sheet,
                i,
                onTap: onTap == null
                    ? null
                    : () {
                        Navigator.of(sheet).pop();
                        onTap(i);
                      },
              ),
          ],
        ),
      ),
    ),
  );
}

/// One installment as a list row: its date, "งวดที่ n", principal / interest
/// on line 2, its status pill and its amount.
Widget installmentRow(
  BuildContext context,
  PlanInstallment i, {
  int? total,
  VoidCallback? onTap,
}) {
  final l = AppLocalizations.of(context)!;
  final symbol = context.readUserCurrencySymbol;
  String money(double v) => moneyString(context, v, symbol: symbol);
  final (String pill, Tone? tone) = switch (i.status) {
    InstallmentStatus.paid => (l.recurringInstallmentPaid, Tone.success),
    InstallmentStatus.due => (l.recurringInstallmentDue, Tone.warning),
    InstallmentStatus.skipped => (l.recurringInstallmentSkipped, null),
    InstallmentStatus.upcoming => (l.recurringInstallmentUpcoming, null),
  };
  return PpForgeListRow(
    key: ValueKey('installment-${i.seq}'),
    leading: DateTile(date: i.dueDate),
    title: total == null
        ? l.recurringInstallmentTitle(i.seq)
        : '${l.recurringInstallmentTitle(i.seq)} / $total',
    line2: ListRowLine(
      spans: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: PpForgeChip(
            label: pill,
            tone: tone == null
                ? PpForgeChipTone.neutral
                : PpForgeChipTone.fromTone(tone),
            selected: tone != null,
            size: ChipSize.mini,
          ),
        ),
        if (i.interest > 0)
          TextSpan(
            text: l.recurringPlanSplit(money(i.principal), money(i.interest)),
          ),
      ],
    ),
    trailing: ListRowTrailing.text(money(i.amount)),
    dimmed: i.status == InstallmentStatus.skipped,
    onTap: onTap,
  );
}
