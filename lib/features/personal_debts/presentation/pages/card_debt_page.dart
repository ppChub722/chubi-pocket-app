import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../recurring/domain/recurring.dart' show RecurringKind;
import '../../../recurring/domain/rule_draft.dart';
import '../../../recurring/domain/rule_group.dart';
import '../../../recurring/presentation/widgets/rule_due_box.dart';
import '../../../recurring/presentation/widgets/rules_box.dart';
import '../../../../app/shell/app_page.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../recurring/domain/recurring_page.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
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
  /// Bumped when a rule is saved here: ต้องทำ loads again.
  int _rulesTick = 0;
  CardSummary? _card;

  /// The rows of the bill's cycle (D-Card รายการในรอบบิลนี้).
  List<Transaction> _rows = const [];
  Object? _error;

  PersonalDebtsRepository get _repo => context.read<PersonalDebtsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await _repo.cardSummary(widget.accountId);
      final start = c.bill.cycleStart;
      if (start != null && mounted) {
        final page = await context.read<TransactionsRepository>().list(
          accountId: widget.accountId,
          from: _ymd(start),
          to: _ymd(c.bill.cycleEnd),
          perPage: 10,
        );
        _rows = page.transactions;
      }
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
  /// จ่ายบิล: a transfer into the card, monthly on its statement day, the
  /// amount asked each round (the BE prefills it with the bill).
  RuleDraft _billPreset(CardSummary c) {
    final day = c.bill.cycleEnd.day;
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, day);
    if (start.isBefore(DateTime(now.year, now.month, now.day))) {
      start = DateTime(now.year, now.month + 1, day);
    }
    return RuleDraft.blank(
      RecurringKind.transfer,
      start: start,
    ).copyWith(toAccount: c.account, ask: true);
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _date(DateTime d) =>
      DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = _card;
    return AppPage(
      topBar: AppTopBar(
        title: c?.account.name ?? l.debtsSectionCards,
        showBack: true,
      ),
      body: c == null
          ? (_error != null
                ? EmptyView.compact(message: '$_error')
                : const Center(child: PpForgeSpinner()))
          : RefreshIndicator(
              onRefresh: _load,
              child: Builder(
                builder: (context) => ListView(
                  padding: AppPage.scrollPadding(context),
                  children: _body(l, c),
                ),
              ),
            ),
    );
  }

  /// D-Card: what the card holds (and of its limit), the bill (spending + each
  /// plan's round billed), the plan principal not billed yet; ชำระบัตร (its
  /// bill reminder); its plans (+ ผ่อนใหม่); its rows (the wallet page).
  List<Widget> _body(AppLocalizations l, CardSummary c) {
    final limit = c.creditLimit;
    final used = limit == null || limit <= 0
        ? null
        : (c.owed / limit * 100).round();
    String m(double v) => moneyString(context, v);
    return [
      SectionCard(
        first: true,
        title: c.account.name,
        description: limit == null ? null : l.debtCardLimit(m(limit)),
        children: [
          InfoRow(
            label: l.debtCardOwed,
            valueWidget: MoneyText(c.owed, tone: MoneyTone.expense),
          ),
          if (used != null) InfoRow(label: l.debtCardUsed('$used')),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        title: l.debtCardBillOf(_date(c.bill.cycleEnd)),
        description: c.bill.dueDate == null
            ? null
            : l.debtCardDue(_date(c.bill.dueDate!)),
        children: [
          InfoRow(
            label: l.debtCardSpending,
            valueWidget: MoneyText(c.bill.spending),
          ),
          for (final p in c.plans)
            if (p.installments.any(
              (i) =>
                  !i.dueDate.isAfter(c.bill.cycleEnd) &&
                  i.dueDate.isAfter(
                    c.bill.cycleEnd.subtract(const Duration(days: 31)),
                  ),
            ))
              InfoRow(
                label: '${p.name} · ${l.debtCardPlanRound(_billedSeq(p, c))}',
                valueWidget: MoneyText(_billedAmount(p, c)),
              ),
          InfoRow(label: l.debtCardPaid, valueWidget: MoneyText(c.bill.paid)),
          InfoRow(
            label: l.debtCardLeft,
            valueWidget: MoneyText(
              c.bill.left,
              tone: c.bill.left > 0 ? MoneyTone.expense : MoneyTone.plain,
            ),
          ),
          InfoRow(
            label: l.debtCardUnbilled,
            valueWidget: MoneyText(c.unbilled),
          ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.md),
      // ต้องทำ: the due rounds of those rules (the bill round first)
      RuleDueBox(
        key: ValueKey('cardDue:${c.account.id}'),
        filter: RuleFilter.wallet(c.account.id),
        reloadKey: _rulesTick,
        onChanged: () => unawaited(_load()),
      ),
      // รายการอัตโนมัติ: rules from or into this card (spec §2.3, §3; mock
      // CardNew): the bill rule = a transfer into the card on its statement
      // day, the amount asked (prefilled with the bill)
      RulesBox(
        key: ValueKey('cardRules:${c.account.id}'),
        filter: RuleFilter.wallet(c.account.id),
        preset: _billPreset(c),
        newName: l.rulesNewNameCard(c.account.name),
        addLabel: l.rulesBoxCardAdd,
        trackingType: 'credit_card',
        onChanged: () {
          setState(() => _rulesTick++);
          unawaited(_load());
        },
      ),
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        title: '${l.debtCardPlans} | ${c.plans.length}',
        children: [
          for (final p in c.plans)
            PpForgeListRow(
              key: ValueKey('cardPlan-${p.id}'),
              leading: const PpForgeIcon(
                AppIcons.payLater,
                size: PpForgeIconSize.md,
              ),
              title: p.name,
              line2: ListRowLine(
                parts: [
                  '${p.plan.done}/${p.plan.count}',
                  if (p.plan.purchase != null)
                    l.debtCardPlanBought(
                      _date(p.plan.purchase!.date),
                      m(p.plan.purchase!.amount),
                    ),
                  l.debtPlanLeftToPay,
                  m(p.plan.leftTotal),
                ],
              ),
              trailing: ListRowTrailing.value(
                MoneyText(p.plan.next?.amount ?? 0),
              ),
              onTap: () async {
                await context.push('/personal-debts/plans/${p.id}');
                if (mounted) _load();
              },
            ),
          DueMoreRow(
            key: const ValueKey('cardPlanNew'),
            label: '+ ${l.debtCardNewPlan}',
            onTap: () async {
              await context.push(
                Uri(
                  path: '/personal-debts/plans/new',
                  queryParameters: {
                    'card': c.account.id,
                    'card_name': c.account.name,
                  },
                ).toString(),
              );
              if (mounted) _load();
            },
          ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.md),
      SectionCard(
        key: const ValueKey('cardCycleRows'),
        title: l.debtCardCycleRows,
        children: [
          for (final t in _rows)
            TransactionTile(
              transaction: t,
              showAccount: false,
              showDate: true,
              onTap: () => openPage(context, '/transactions/${t.id}'),
            ),
          DueMoreRow(
            key: const ValueKey('cardRows'),
            label: l.debtPlanAll,
            onTap: () => openPage(context, '/accounts/${c.account.id}'),
          ),
        ],
      ),
    ];
  }

  PlanInstallment? _billed(DebtPlan p, CardSummary c) {
    final end = c.bill.cycleEnd;
    for (final i in p.installments) {
      if (!i.dueDate.isAfter(end) &&
          i.dueDate.isAfter(end.subtract(const Duration(days: 31)))) {
        return i;
      }
    }
    return null;
  }

  String _billedSeq(DebtPlan p, CardSummary c) =>
      '${_billed(p, c)?.seq ?? 0}/${p.plan.count}';

  double _billedAmount(DebtPlan p, CardSummary c) => _billed(p, c)?.amount ?? 0;
}
