import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
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

  Widget _money(double v) => MoneyText(v);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = _plan;
    return Scaffold(
      appBar: AppTopBar(title: p?.name ?? l.debtPlanTitle, showBack: true),
      body: p == null
          ? (_error != null
                ? EmptyView.compact(message: '$_error')
                : const Center(child: PpForgeSpinner()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(PpForgeSpacing.md),
                children: _body(l, p),
              ),
            ),
    );
  }

  List<Widget> _body(AppLocalizations l, DebtPlan p) {
    final v = p.plan;
    final next = v.next;
    return [
      SectionCard(
        first: true,
        title: p.creditorName,
        description: p.plan.closed ? l.debtPlanClosed : null,
        children: [
          InfoRow(
            label: l.debtPlanProgress('${v.done}', '${v.count}'),
            valueWidget: _money(v.leftTotal),
          ),
          InfoRow(
            label: l.debtPlanLeftPrincipal,
            valueWidget: _money(v.leftPrincipal),
          ),
          if (v.leftInterest > 0)
            InfoRow(
              label: l.debtPlanLeftInterest,
              valueWidget: _money(v.leftInterest),
            ),
          if (next != null)
            InfoRow(
              label: '${l.debtPlanNext} · ${_date(next.dueDate)}',
              valueWidget: _money(next.amount),
            ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.md),
      if (p.isCard)
        SectionCard(children: [InfoRow(label: l.debtPlanPaidByBill)])
      else if (!v.closed && next != null)
        PpForgeButton(
          key: const ValueKey('debtPlanPay'),
          label: l.debtPlanPay,
          expand: true,
          loading: _busy,
          onPressed: _busy ? null : _pay,
        ),
      if (!p.isCard && p.recurringId != null) ...[
        const SizedBox(height: PpForgeSpacing.md),
        SectionCard(
          children: [
            InfoRow(
              label: l.debtPlanReminderOpen,
              showChevron: true,
              onTap: () => openPage(context, '/recurring/${p.recurringId}'),
            ),
          ],
        ),
      ],
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        title: l.debtPlanInstallments,
        children: [
          for (final i in p.installments)
            InfoRow(
              key: ValueKey('debtPlanInstallment-${i.seq}'),
              label: l.debtPlanInstallmentRow('${i.seq}', _date(i.dueDate)),
              value: _status(l, i),
              valueWidget: _money(i.amount),
            ),
        ],
      ),
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

  String? _status(AppLocalizations l, PlanInstallment i) => switch (i.status) {
    InstallmentStatus.paid => '✓',
    _ => i.interest > 0 ? l.debtPlanInterest(_fmt(i.interest)) : null,
  };

  String _fmt(double v) => NumberFormat('#,##0.##').format(v);
}
