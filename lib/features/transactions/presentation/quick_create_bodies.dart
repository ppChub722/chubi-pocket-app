import 'package:flutter/widgets.dart';

import '../../personal_debts/domain/debt_ledger.dart';
import '../../projects/domain/project.dart';
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
    amount: c.amountValue,
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

/// The อีเวนต์ tab's bill: `new_transaction` plus the payer + members that go
/// beside it (B2).
({Map<String, dynamic> newTransaction, Map<String, dynamic>? people})
eventBillBody(DraftFormController c, LinkMode mode) {
  final plan = c.linkSave(mode);
  final splits = plan.splits;
  final account = plan.useWallet ? c.account : null;
  return (
    newTransaction: <String, dynamic>{
      'type': c.type.toJson(),
      'amount': c.amountValue,
      'date': _ymd(c.date),
      'account_id': ?account?.id,
      'category_id': ?c.category?.id,
      'description': ?_text(c.description),
      'note': ?_text(c.note),
      if (splits.isNotEmpty) 'splits': splits,
    },
    people: plan.link,
  );
}

typedef ProjectBillBody = ({
  String payerId,
  String type,
  double amount,
  String date,
  String? description,
  String? note,
  List<ProjectSplitInput> splits,
});

/// The event sheet's own bill (a new bill or an edit of one); the tags are
/// resolved by the caller.
ProjectBillBody projectBillBody(DraftFormController c, String payerId) => (
  payerId: payerId,
  type: c.type == TransactionType.income ? 'income' : 'expense',
  amount: c.amountValue,
  date: _ymd(c.date),
  description: _text(c.description),
  note: _text(c.note),
  splits: [
    for (final s in c.memberSplits)
      if (s.memberId != null && s.amountValue > 0)
        ProjectSplitInput(memberId: s.memberId!, amount: s.amountValue),
  ],
);

typedef DebtRecordBody = ({
  String key,
  DebtEntryDirection direction,
  double amount,
  DateTime date,
  String? accountId,
  bool createTransaction,
  String? description,
  String? note,
  List<String>? tagIds,
  String? personName,
  DateTime? dueDate,
});

DebtRecordBody debtRecordBody(DebtEntryController d, DebtPick person) => (
  key: person.key,
  direction: d.direction,
  amount: d.amountValue,
  date: d.date,
  accountId: d.createTransaction ? d.account?.id : null,
  createTransaction: d.createTransaction,
  description: _text(d.description),
  note: _text(d.note),
  tagIds: d.createTransaction ? d.tagIds.toList() : null,
  personName: person.typedName,
  dueDate: d.dueDate,
);

typedef DebtRepaymentBody = ({
  String key,
  DebtRepaymentKind kind,
  double amount,
  String? accountId,
  DateTime date,
  String? description,
  String? note,
  List<String> tagIds,
  List<String> markPaidIds,
  String? personName,
});

DebtRepaymentBody debtRepaymentBody(DebtEntryController d, DebtPick person) => (
  key: person.key,
  kind: d.repayKind,
  amount: d.amountValue,
  accountId: d.account?.id,
  date: d.date,
  description: _text(d.description),
  note: _text(d.note),
  tagIds: d.tagIds.toList(),
  markPaidIds: d.markPaidIds.toList(),
  personName: person.typedName,
);

typedef DebtPreviewBody = ({
  String key,
  DebtEntryDirection? direction,
  DebtRepaymentKind? kind,
  double amount,
  String? accountId,
  bool? createTransaction,
  String? personName,
});

DebtPreviewBody debtPreviewBody(DebtEntryController d, DebtPick person) => (
  key: person.key,
  direction: d.repaying ? null : d.direction,
  kind: d.repaying ? d.repayKind : null,
  amount: d.amountValue,
  accountId: d.repaying || d.createTransaction ? d.account?.id : null,
  createTransaction: d.repaying ? null : d.createTransaction,
  personName: person.typedName,
);

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
