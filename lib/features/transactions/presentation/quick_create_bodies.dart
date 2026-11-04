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

typedef PaperBodies = ({
  Map<String, dynamic> paper,
  Map<String, dynamic> myBooks,

  /// An event bill with "ลงรายการของฉันเลย" off: the paper only.
  bool skipMyBooks,

  /// The people (by their place in `paper.people`) marked "คืนแล้ว": a mark
  /// set after the paper is made.
  List<int> paidBack,
});

/// The แบ่ง card as ONE paper (paper model 2026-11-02): a split bill
/// ([LinkMode.split] I paid, [LinkMode.paid] someone else paid, maybe part
/// by me) or an event bill ([LinkMode.event]). Every person carries their
/// share of the whole bill and what they paid; the note is my private note
/// (owner 2026-11-03: the note row is mine). Null = no people yet.
PaperBodies? paperBodies(
  DraftFormController c,
  LinkMode mode, {
  Map<String, String> personIds = const {},
  String? mePersonId,
}) {
  if (c.isTransfer || mode == LinkMode.personal) return null;
  // An edit keeps each person's row (their books stay linked to it): a kept
  // row is its person_id alone (the BE takes exactly one way to name a
  // person).
  Map<String, dynamic> keep(LinkPerson p) => switch (personIds[p.key]) {
    final id? => {'person_id': id},
    _ => p.toJson(),
  };
  final amount = c.amountValue;
  final people = <Map<String, dynamic>>[];
  final paidBack = <int>[];
  LinkPerson? payer;
  var myPaid = 0.0;
  var mine = 0.0;
  if (mode == LinkMode.event) {
    final members = c.eventMembers;
    payer = c.link.eventPayer;
    mine = c.link.eventMine(amount, members);
    myPaid = payer == null ? amount : 0;
    for (final p in members) {
      if (c.isPaidBack(p) && p != payer) paidBack.add(people.length + 1);
      people.add({
        ...keep(p),
        'share': c.link.eventShareOf(p, amount, members),
        'paid': p == payer ? amount : 0,
      });
    }
  } else {
    // Everyone on the แบ่ง rows with what they owe (rows of one person add
    // up).
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
    if (mode == LinkMode.paid) {
      payer = c.link.paidBy;
      if (payer == null) return null;
      myPaid = c.link.myPaid(amount);
    } else {
      if (owed.isEmpty) return null;
      myPaid = amount;
    }
    mine = c.myShareFor(mode);
    var othersShare = 0.0;
    for (final o in owed.values) {
      if (o.person == payer) continue;
      othersShare += o.share;
      if (c.isPaidBack(o.person)) paidBack.add(people.length + 1);
      people.add({...keep(o.person), 'share': o.share, 'paid': 0});
    }
    // The payer's own share is the rest of the bill.
    final p = payer;
    if (p != null) {
      people.add({
        ...keep(p),
        'share': _round2(amount - mine - othersShare),
        'paid': _round2(amount - myPaid),
      });
    }
  }
  // "คืน X แล้ว" on my row: my share from my wallet, no debt.
  final mePaidBack = payer != null && myPaid <= 0.005 && c.link.mePaidBack;
  final event = mode == LinkMode.event;
  final debts = event && (c.link.eventBookDebts ?? false);
  final myTx = !event || c.link.eventBookMine;
  return (
    paper: {
      'type': c.type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'date': _ymd(c.date),
      'description': _text(c.description),
      'split_mode': 'custom',
      'people': [
        {
          // My row kept by its id (as `me` it would be a new row and the old
          // one would read as removed).
          if (mePersonId != null) 'person_id': mePersonId else 'me': true,
          'share': _round2(mine),
          'paid': _round2(myPaid),
        },
        ...people,
      ],
    },
    myBooks: {
      'pay': mePaidBack ? 'wallet' : 'debt',
      // Someone else paid it all: my share takes no wallet ("จ่ายโดย X")
      // until I paid them back.
      'account_id': myPaid > 0.005 || mePaidBack ? c.account?.id : null,
      'category_id': c.isTransfer ? null : c.category?.id,
      'tag_ids': c.tagIds.toList(),
      'private_note': _text(c.note),
      // An event bill's debts now; else the event's lump makes them.
      if (debts) 'book_debts': true,
      // Debts without my transaction ("ลงรายการของฉันเลย" off).
      if (debts && !myTx) 'skip_transaction': true,
    },
    // Neither: the paper only.
    skipMyBooks: !myTx && !debts,
    paidBack: paidBack,
  );
}

double _round2(double v) => (v * 100).roundToDouble() / 100;

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
