import 'package:flutter/widgets.dart';

import '../../personal_debts/domain/debt_ledger.dart';
import '../../saving_goals/domain/saving_entry.dart';
import '../domain/link_draft.dart';
import '../domain/transaction_type.dart';
import 'widgets/debt_entry_form.dart';
import 'widgets/draft_form.dart';
import 'widgets/saving_entry_form.dart';

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String? _text(TextEditingController c) =>
    c.text.trim().isEmpty ? null : c.text.trim();

typedef TxCreateBody = ({
  TransactionType type,
  String? accountId,
  double amount,
  String date,
  String? categoryId,
  String? description,
  String? note,
  String? transferToAccountId,
  List<String> tagIds,
  List<Map<String, dynamic>>? splits,
  Map<String, dynamic>? link,
});

/// What a new tx sends for the active ผูกกับ tab [mode] (owner 2026-10-21).
TxCreateBody txCreateBody(DraftFormController c, LinkMode mode) {
  final plan = c.linkSave(mode);
  final splits = plan.splits;
  return (
    type: c.type,
    accountId: plan.useWallet ? c.account?.id : null,
    amount: c.saveAmountFor(mode),
    date: _ymd(c.date),
    categoryId: c.isTransfer ? null : c.category?.id,
    description: _text(c.description),
    note: _text(c.note),
    transferToAccountId: c.isTransfer ? c.toAccount?.id : null,
    tagIds: c.tagIds.toList(),
    splits: splits.isEmpty ? null : splits,
    link: plan.link,
  );
}

/// 0.4.1-2 SA7 — แบ่งกับคน / คนจ่ายแทน (รับแทน) as ONE split-bill call
/// (`POST /event-bills {split: true}`): [bill] = payer + everyone's share
/// ("คืนแล้ว" per person), [myBooks] = my copy (tx + debts, wallet,
/// category, my tags). จ่ายแทน where I also paid part from my wallet is a
/// bill with two payers (0.4.1-2 multi-payer: `payers` me + them, every
/// share listed). Null = this form isn't a split bill (no people).
({Map<String, dynamic> bill, Map<String, dynamic> myBooks})? splitBookBodies(
  DraftFormController c,
  LinkMode mode,
) {
  if (c.isTransfer) return null;
  final amount = c.amountValue;
  // Everyone on the แบ่ง rows with what they owe (rows of one person add up).
  final owed = <String, ({LinkPerson person, double share})>{};
  for (final s in c.splits.where((s) => s.isComplete)) {
    final p = LinkPerson(
      name: s.personName.trim(),
      contactId: s.contactId,
      person: s.person,
    );
    final had = owed[p.key]?.share ?? 0;
    owed[p.key] = (person: p, share: had + (s.owedAmount ?? 0));
  }
  final LinkPerson? payer;
  // จ่ายแทน, I paid part too: me + them as payers (123 = me 110 + ลี 13).
  var myPaid = 0.0;
  switch (mode) {
    case LinkMode.split:
      if (owed.isEmpty) return null;
      payer = null;
    case LinkMode.paid:
      final by = c.link.paidBy;
      if (by == null) return null;
      payer = by;
      myPaid = c.link.myPaid(amount);
    case LinkMode.personal || LinkMode.event:
      return null;
  }
  final twoPayers = payer != null && myPaid > 0.005;
  final mine = c.myShareFor(mode);
  // One payer: their own share is the rest of the bill (EventBillInput), so
  // they need not be listed. Two payers: every share is (Σ = the bill).
  // "คืนแล้ว" on anyone but a payer, me too (SA6).
  final mePaidBack = payer != null && !twoPayers && c.link.mePaidBack;
  final others = [
    for (final o in owed.values)
      if (o.person != payer) o,
  ];
  final payerShare =
      amount - mine - others.fold<double>(0, (s, o) => s + o.share);
  final members = <Map<String, dynamic>>[
    {'me': true, 'share': mine, if (mePaidBack) 'paid_back': true},
    for (final o in others)
      {
        ...o.person.toJson(),
        'share': o.share,
        if (c.isPaidBack(o.person)) 'paid_back': true,
      },
    if (twoPayers) {...payer.toJson(), 'share': payerShare},
  ];
  return (
    bill: {
      'kind': c.type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'date': _ymd(c.date),
      'description': _text(c.description),
      'note': _text(c.note),
      if (twoPayers)
        'payers': [
          {'me': true, 'amount': myPaid},
          {...payer.toJson(), 'amount': amount - myPaid},
        ]
      else
        'payer': payer?.toJson() ?? const {'me': true},
      'members': members,
    },
    myBooks: {
      'on': true,
      'tx': true,
      'debt': true,
      // Someone else paid it all: my share takes no wallet ("จ่ายโดย X")
      // until I paid them back; I paid part: that part is from my wallet.
      'account_id': payer == null || mePaidBack || twoPayers
          ? c.account?.id
          : null,
      'category_id': c.category?.id,
      'tag_ids': c.tagIds.toList(),
    },
  );
}

typedef DebtRecordBody = ({
  String key,
  DebtEntryDirection direction,
  double? amount,
  DateTime date,
  String? accountId,
  bool createTransaction,
  String? linkTransactionId,
  String? description,
  String? note,
  List<String>? tagIds,
  String? personName,
  DateTime? dueDate,
});

/// ให้ยืม / ยืม. "บันทึกในรายการ" off = ledger-only; on = a new transaction
/// (wallet optional, tags) or, when one was picked, an existing one connected
/// (its amount and date win, so none is sent).
DebtRecordBody debtRecordBody(DebtEntryController d, DebtPick person) {
  final link = d.createTransaction ? d.linkedTx?.id : null;
  final make = d.createTransaction && link == null;
  return (
    key: person.key,
    direction: d.direction,
    amount: link == null ? d.amountValue : null,
    date: d.date,
    accountId: make ? d.account?.id : null,
    createTransaction: make,
    linkTransactionId: link,
    description: _text(d.description),
    note: _text(d.note),
    tagIds: make ? d.tagIds.toList() : null,
    personName: person.typedName,
    dueDate: d.dueDate,
  );
}

typedef DebtRepaymentBody = ({
  String key,
  DebtRepaymentKind kind,
  double? amount,
  String? accountId,
  bool createTransaction,
  String? linkTransactionId,
  DateTime date,
  String? description,
  String? note,
  List<String> tagIds,
  List<String> markPaidIds,
  bool markAllPaid,
  String? personName,
});

/// จ่ายคืน / รับคืน (0.4.1-1 D3 / D10): a person-book row like a debt, the
/// transaction side the same as [debtRecordBody]; ปิดหนี้ = [markAllPaid].
DebtRepaymentBody debtRepaymentBody(DebtEntryController d, DebtPick person) {
  final link = d.createTransaction ? d.linkedTx?.id : null;
  final make = d.createTransaction && link == null;
  return (
    key: person.key,
    kind: d.repayKind,
    amount: link == null ? d.amountValue : null,
    accountId: make ? d.account?.id : null,
    createTransaction: make,
    linkTransactionId: link,
    date: d.date,
    description: _text(d.description),
    note: _text(d.note),
    tagIds: make ? d.tagIds.toList() : const [],
    markPaidIds: d.markPaidIds.toList(),
    markAllPaid: d.closeDebt,
    personName: person.typedName,
  );
}

typedef DebtPreviewBody = ({
  String key,
  DebtEntryDirection? direction,
  DebtRepaymentKind? kind,
  double amount,
  String? accountId,
  bool? createTransaction,
  String? personName,
});

DebtPreviewBody debtPreviewBody(DebtEntryController d, DebtPick person) {
  final make = d.createTransaction && d.linkedTx == null;
  return (
    key: person.key,
    direction: d.repaying ? null : d.direction,
    kind: d.repaying ? d.repayKind : null,
    amount: d.amountValue,
    accountId: make ? d.account?.id : null,
    createTransaction: make,
    personName: person.typedName,
  );
}

typedef SavingSaveBody = ({
  SavingEntryKind kind,
  double amount,
  String date,
  String? goalId,
  String? walletId,
  String? note,
});

SavingSaveBody savingSaveBody(SavingEntryController s) => (
  kind: SavingEntryKind.save,
  amount: s.amountValue,
  date: _ymd(s.date),
  goalId: s.goalId,
  walletId: s.account?.id,
  note: _text(s.note),
);
