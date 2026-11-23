import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/debt_plans.dart';

/// หนี้แบบที่ 1 · บัตร / PayLater (0.4.3): the card is the creditor and the
/// debt is its balance. Its last bill (spending in the cycle + the plan
/// installments billed in it; what was paid after the statement; what is
/// left), the installments not billed yet, its plans, and the reminder that
/// pays its bill (a transfer into the card, amount = the bill's left).
class CardDebtPage extends StatefulWidget {
  const CardDebtPage({required this.accountId, super.key});

  final String accountId;

  @override
  State<CardDebtPage> createState() => _CardDebtPageState();
}

class _CardDebtPageState extends State<CardDebtPage> {
  CardSummary? _card;
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
      final c = await _repo.cardSummary(widget.accountId);
      if (mounted) {
        setState(() {
          _card = c;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// A monthly bill reminder on the due day, from the wallet picked.
  Future<void> _addReminder(CardSummary c) async {
    final l = AppLocalizations.of(context)!;
    final r = await AccountPicker.one(
      context,
      title: l.debtPlanPayFrom,
      excludeIds: {c.account.id},
    );
    if (!mounted || r is! AccountPicked) return;
    setState(() => _busy = true);
    try {
      final id = await _repo.createCardBillReminder(
        accountId: c.account.id,
        name: '${l.debtCardBillReminderSet} ${c.account.name}',
        fromAccountId: r.account.id,
        day: (c.bill.dueDate ?? DateTime.now()).day,
      );
      if (mounted) openPage(context, '/recurring/$id');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = _card;
    return Scaffold(
      appBar: AppTopBar(title: c?.account.name ?? l.debtsSectionCards, showBack: true),
      body: c == null
          ? (_error != null
                ? EmptyView.compact(message: '$_error')
                : const Center(child: PpForgeSpinner()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(PpForgeSpacing.md),
                children: [
                  SectionCard(
                    first: true,
                    children: [
                      InfoRow(
                        label: l.debtCardOwed,
                        valueWidget: MoneyText(c.owed, tone: MoneyTone.expense),
                      ),
                    ],
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
                  SectionCard(
                    title: l.debtCardBill,
                    description: c.bill.dueDate == null
                        ? null
                        : l.debtCardDue(_date(c.bill.dueDate!)),
                    children: [
                      InfoRow(
                        label: l.debtCardSpending,
                        valueWidget: MoneyText(c.bill.spending),
                      ),
                      InfoRow(
                        label: l.debtCardBilledInstallments,
                        valueWidget: MoneyText(c.bill.installments),
                      ),
                      InfoRow(
                        label: l.debtCardPaid,
                        valueWidget: MoneyText(c.bill.paid),
                      ),
                      InfoRow(
                        label: l.debtCardLeft,
                        valueWidget: MoneyText(
                          c.bill.left,
                          tone: c.bill.left > 0
                              ? MoneyTone.expense
                              : MoneyTone.plain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
                  SectionCard(
                    children: [
                      if (c.recurringId != null)
                        InfoRow(
                          label: l.debtCardBillReminderSet,
                          showChevron: true,
                          onTap: () => openPage(context, '/recurring/${c.recurringId}'),
                        )
                      else
                        InfoRow(
                          key: const ValueKey('cardBillReminderAdd'),
                          label: l.debtCardBillReminder,
                          showChevron: true,
                          onTap: _busy ? null : () => _addReminder(c),
                        ),
                    ],
                  ),
                  if (c.plans.isNotEmpty) ...[
                    const SizedBox(height: PpForgeSpacing.md),
                    SectionCard(
                      title: l.debtCardPlans,
                      description: '${l.debtCardUnbilled} '
                          '${NumberFormat('#,##0.##').format(c.unbilled)}',
                      children: [
                        for (final p in c.plans)
                          InfoRow(
                            key: ValueKey('cardPlan-${p.id}'),
                            label:
                                '${p.name} · ${p.plan.done}/${p.plan.count}',
                            valueWidget: MoneyText(p.plan.next?.amount ?? 0),
                            showChevron: true,
                            onTap: () async {
                              await context.push('/personal-debts/plans/${p.id}');
                              if (mounted) _load();
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
