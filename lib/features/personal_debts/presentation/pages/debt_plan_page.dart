import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../recurring/domain/recurring.dart' show PlanInterestMethod;
import '../../../recurring/domain/recurring_page.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_plans.dart';

/// แผนผ่อน (0.4.3, debts page): what is left (principal + interest), the next
/// installment and "จ่ายงวดนี้" (the principal back + its ดอกเบี้ย from a
/// wallet; a card plan is paid by its card's bill), every installment, the
/// reminder that pays it, close early / delete.
class DebtPlanPage extends StatefulWidget {
  const DebtPlanPage({required this.id, super.key});

  final String id;

  @override
  State<DebtPlanPage> createState() => _DebtPlanPageState();
}

class _DebtPlanPageState extends State<DebtPlanPage> {
  DebtPlan? _plan;
  Object? _error;
  bool _busy = false;
  bool _allUpcoming = false;
  bool _allPast = false;

  PersonalDebtsRepository get _repo => context.read<PersonalDebtsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.plan(widget.id);
      if (mounted) {
        setState(() {
          _plan = p;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<DebtPlan?> Function() op) async {
    setState(() => _busy = true);
    try {
      final p = await op();
      if (mounted && p != null) setState(() => _plan = p);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final l = AppLocalizations.of(context)!;
    final r = await AccountPicker.one(
      context,
      title: l.debtPlanPayFrom,
      allowNone: true,
    );
    if (!mounted || r == null) return;
    final acc = r is AccountPicked ? r.account.id : null;
    await _run(() => _repo.payInstallment(widget.id, accountId: acc));
  }

  /// ตั้ง reminder: a debt item paying this plan from the wallet picked,
  /// monthly from the next installment for what is left.
  Future<void> _addReminder(DebtPlan p) async {
    final l = AppLocalizations.of(context)!;
    final next = p.plan.next;
    if (next == null) return;
    final r = await AccountPicker.one(context, title: l.debtPlanPayFrom);
    if (!mounted || r is! AccountPicked) return;
    setState(() => _busy = true);
    try {
      final id = await _repo.createPlanReminder(
        planId: p.id,
        name: p.name,
        fromAccountId: r.account.id,
        first: next.dueDate,
        left: p.plan.leftCount,
      );
      await _load();
      if (mounted) openPage(context, '/recurring/$id');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// แก้งวดนี้: its due date, amount and interest (principal = the rest).
  Future<void> _editOne(PlanInstallment i) async {
    final l = AppLocalizations.of(context)!;
    final amount = TextEditingController(text: _plain(i.amount));
    final interest = TextEditingController(text: _plain(i.interest));
    var due = i.dueDate;
    final ok = await showPpForgeSheet<bool>(
      context,
      title: l.debtPlanEditOne,
      padded: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoRow(
              label: l.debtPlanStart,
              valueWidget: DatePickChip(
                date: due,
                onPick: () async {
                  final r = await PpForgeDatePicker.show(
                    ctx,
                    initial: due,
                    first: DateTime(2000),
                    last: DateTime(2100),
                  );
                  if (r is PpForgeDatePicked) set(() => due = r.date);
                },
              ),
            ),
            const SizedBox(height: PpForgeSpacing.sm),
            PpForgeInput(
              controller: amount,
              label: l.debtPlanInstallmentAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: PpForgeSpacing.sm),
            PpForgeInput(
              controller: interest,
              label: l.debtPlanInterestLabel,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: PpForgeSpacing.md),
            PpForgeButton(
              key: const ValueKey('debtPlanEditSave'),
              label: l.debtPlanSave,
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      ),
    );
    final a = AmountInput.parse(amount.text);
    final it = AmountInput.parse(interest.text);
    amount.dispose();
    interest.dispose();
    if (ok != true || !mounted) return;
    await _run(
      () => _repo.editInstallment(
        widget.id,
        i.seq,
        dueDate: due,
        amount: a,
        interest: it,
      ),
    );
  }

  /// ข้าม: not paid now; it moves to the end of the plan.
  Future<void> _skip(PlanInstallment i) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtPlanSkip,
      message: l.debtPlanSkipConfirm('${i.seq}'),
      confirmLabel: l.debtPlanSkip,
    );
    if (ok && mounted) {
      await _run(() => _repo.skipInstallment(widget.id, i.seq));
    }
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Future<void> _close() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtPlanClose,
      confirmLabel: l.debtPlanClose,
    );
    if (ok && mounted) await _run(() => _repo.closePlan(widget.id));
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.debtPlanDelete,
      message: l.debtPlanDeleteConfirm,
      confirmLabel: l.debtPlanDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.deletePlan(widget.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e);
        setState(() => _busy = false);
      }
    }
  }

  String _date(DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _plan;
    return AppPage(
      topBar: AppTopBar(title: p?.name ?? l.debtPlanTitle, showBack: true),
      body: p == null
          ? (_error != null
                ? EmptyView.compact(message: '$_error')
                : const Center(child: PpForgeSpinner()))
          : RefreshIndicator(
              onRefresh: _load,
              child: Builder(
                builder: (context) => ListView(
                  padding: AppPage.scrollPadding(context),
                  children: _body(l, p),
                ),
              ),
            ),
    );
  }

  String _m(double v) => moneyString(context, v);

  String _method(AppLocalizations l, RecurringPlan v) => switch (v.method) {
    PlanInterestMethod.none => l.debtPlanMethodNone,
    PlanInterestMethod.flat => '${l.debtPlanMethodFlat} ${v.rate ?? 0}%',
    PlanInterestMethod.reducing =>
      '${l.debtPlanMethodReducing} ${v.rate ?? 0}%',
    PlanInterestMethod.fixed => l.debtPlanMethodFixed,
    _ => '',
  };

  String _creditorKind(AppLocalizations l, DebtPlan p) =>
      switch (p.creditorKind) {
        'card' => l.debtPlanCreditorCard,
        'institution' => l.debtPlanCreditorInstitution,
        _ => l.debtPlanCreditorPerson,
      };

  /// An installment row (ที่จะมา / ที่ผ่านมา): date, งวด n/N, ต้น · ดอก.
  Widget _installmentRow(AppLocalizations l, DebtPlan p, PlanInstallment i) =>
      PpForgeListRow(
        key: ValueKey('debtPlanInstallment-${i.seq}'),
        leading: DateTile(date: i.dueDate),
        title: i.paid
            ? l.debtPlanSeqPaid('${i.seq}', '${p.plan.count}')
            : l.debtPlanSeq('${i.seq}', '${p.plan.count}'),
        line2: ListRowLine(
          parts: [l.debtPlanSplitShort(_m(i.principal), _m(i.interest))],
        ),
        trailing: ListRowTrailing.value(MoneyText(i.amount)),
      );

  /// D-Car: the hero (creditor, n/N, paid / left / last installment, principal
  /// and interest left), the next installment with its split and จ่ายงวดนี้,
  /// the reminder box, the contract's totals, ที่จะมา (3) and ที่ผ่านมา.
  List<Widget> _body(AppLocalizations l, DebtPlan p) {
    final v = p.plan;
    final next = v.next;
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming = [
      for (final i in p.installments)
        if (!i.paid &&
            i.status != InstallmentStatus.skipped &&
            i.seq != next?.seq)
          i,
    ];
    final past = [
      for (final i in p.installments.reversed)
        if (i.paid) i,
    ];
    final interestAll = p.installments.fold<double>(
      0,
      (s, i) => s + i.interest,
    );
    final paidInterest = v.paidTotal - v.paidPrincipal;
    return [
      SectionCard(
        first: true,
        title: p.name,
        description: [
          _creditorKind(l, p),
          l.debtPlanCountLabel('${v.count}'),
          _method(l, v),
          if (v.closed) l.debtPlanClosed,
        ].where((x) => x.isNotEmpty).join(' · '),
        children: [
          InfoRow(label: l.debtPlanCreditor, value: p.creditorName),
          InfoRow(
            label: l.debtPlanProgressLabel,
            value: '${v.done}/${v.count}',
          ),
          InfoRow(label: l.debtCardPaid, valueWidget: MoneyText(v.paidTotal)),
          InfoRow(
            label: l.debtPlanLeftToPay,
            valueWidget: MoneyText(v.leftTotal),
          ),
          if (v.lastDate != null)
            InfoRow(label: l.debtPlanLastDate, value: _date(v.lastDate!)),
          InfoRow(
            label: l.debtPlanLeftPrincipal,
            valueWidget: MoneyText(v.leftPrincipal),
          ),
          InfoRow(
            label: l.debtPlanLeftInterest,
            valueWidget: MoneyText(v.leftInterest),
          ),
        ],
      ),
      if (next != null && !v.closed) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          key: const ValueKey('debtPlanNextCard'),
          title: l.debtPlanNextIn(
            '${next.seq}',
            '${v.count}',
            '${DateUtils.dateOnly(next.dueDate).difference(today).inDays}',
          ),
          description: _date(next.dueDate),
          children: [
            InfoRow(
              label: l.debtPlanSplit(_m(next.principal), _m(next.interest)),
              valueWidget: MoneyText(next.amount),
            ),
            if (p.isCard) InfoRow(label: l.debtPlanPaidByBill),
            Padding(
              padding: const EdgeInsets.all(PpForgeSpacing.md),
              child: Row(
                children: [
                  if (!p.isCard) ...[
                    Expanded(
                      child: PpForgeButton(
                        key: const ValueKey('debtPlanPay'),
                        label: l.debtPlanPay,
                        expand: true,
                        loading: _busy,
                        onPressed: _busy ? null : _pay,
                      ),
                    ),
                    const SizedBox(width: PpForgeSpacing.sm),
                  ],
                  Expanded(
                    child: PpForgeButton(
                      key: const ValueKey('debtPlanEdit'),
                      label: l.debtPlanEditOne,
                      variant: PpForgeButtonVariant.outlined,
                      expand: true,
                      onPressed: _busy ? null : () => _editOne(next),
                    ),
                  ),
                  const SizedBox(width: PpForgeSpacing.sm),
                  Expanded(
                    child: PpForgeButton(
                      key: const ValueKey('debtPlanSkip'),
                      label: l.debtPlanSkip,
                      variant: PpForgeButtonVariant.outlined,
                      expand: true,
                      onPressed: _busy ? null : () => _skip(next),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      if (!p.isCard &&
          (p.recurringId != null || (!v.closed && next != null))) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          description: p.recurringId == null ? l.debtPlanNoReminder : null,
          children: [
            if (p.recurringId != null)
              InfoRow(
                label: l.debtPlanReminderOpen,
                value: '✓',
                showChevron: true,
                onTap: () => openPage(context, '/recurring/${p.recurringId}'),
              )
            else
              InfoRow(
                key: const ValueKey('debtPlanReminderAdd'),
                label: '+ ${l.debtPlanReminder}',
                showChevron: true,
                onTap: _busy ? null : () => _addReminder(p),
              ),
          ],
        ),
      ],
      if (past.isNotEmpty) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          key: const ValueKey('debtPlanChart'),
          title: l.debtPlanChart,
          children: [
            Padding(
              padding: const EdgeInsets.all(PpForgeSpacing.md),
              child: PairedBarChart(
                groups: [
                  for (final i in past.reversed)
                    BarPair(label: '${i.seq}', a: i.principal, b: i.interest),
                ],
                colorA: Theme.of(context).colorScheme.primary,
                colorB: Tone.warning.color(context),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        children: [
          InfoRow(
            label: l.debtPlanPrincipalTotal,
            valueWidget: MoneyText(v.principal),
          ),
          InfoRow(
            label: l.debtPlanInterestTotal,
            valueWidget: MoneyText(interestAll),
          ),
          InfoRow(
            label: l.debtPlanPaidSplitLabel,
            value: '${_m(v.paidPrincipal)} / ${_m(paidInterest)}',
          ),
        ],
      ),
      if (upcoming.isNotEmpty) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          title: l.debtPlanUpcoming,
          children: [
            for (final i in upcoming.take(_allUpcoming ? upcoming.length : 3))
              _installmentRow(l, p, i),
            if (upcoming.length > 3)
              DueMoreRow(
                key: const ValueKey('debtPlanAllUpcoming'),
                label: _allUpcoming ? l.debtPlanLess : l.debtPlanAll,
                onTap: () => setState(() => _allUpcoming = !_allUpcoming),
              ),
          ],
        ),
      ],
      if (past.isNotEmpty) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          title: l.debtPlanPast,
          children: [
            for (final i in past.take(_allPast ? past.length : 3))
              _installmentRow(l, p, i),
            if (past.length > 3)
              DueMoreRow(
                key: const ValueKey('debtPlanAllPast'),
                label: _allPast ? l.debtPlanLess : l.debtPlanAll,
                onTap: () => setState(() => _allPast = !_allPast),
              ),
          ],
        ),
      ],
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        children: [
          if (!v.closed)
            InfoRow(label: l.debtPlanClose, onTap: _busy ? null : _close),
          InfoRow(label: l.debtPlanDelete, onTap: _busy ? null : _delete),
        ],
      ),
    ];
  }
}
