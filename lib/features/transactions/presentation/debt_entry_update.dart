import 'package:equatable/equatable.dart';

import '../../personal_debts/data/personal_debts_repository.dart';
import '../../personal_debts/domain/debt_ledger.dart';

class DebtEntryDraft extends Equatable {
  const DebtEntryDraft({
    required this.direction,
    required this.amount,
    required this.description,
    required this.note,
    required this.date,
    required this.accountId,
    required this.personKey,
    required this.tagIds,
    required this.paid,
    required this.createTx,
    required this.due,
  });

  /// กำหนดจ่าย, YYYY-MM-DD.
  final String? due;

  final DebtEntryDirection direction;
  final String amount;
  final String description;
  final String note;
  final String date;
  final String? accountId;
  final String personKey;
  final List<String> tagIds;
  final bool paid;

  final bool createTx;

  DebtEntryDraft copyWith({bool? paid}) => DebtEntryDraft(
    direction: direction,
    amount: amount,
    description: description,
    note: note,
    date: date,
    accountId: accountId,
    personKey: personKey,
    tagIds: tagIds,
    paid: paid ?? this.paid,
    createTx: createTx,
    due: due,
  );

  /// Without the entry's own transaction (its wallet and tags went with it).
  DebtEntryDraft withoutTx() => DebtEntryDraft(
    direction: direction,
    amount: amount,
    description: description,
    note: note,
    date: date,
    accountId: null,
    personKey: personKey,
    tagIds: const [],
    paid: paid,
    createTx: false,
    due: due,
  );

  @override
  List<Object?> get props => [
    due,
    direction,
    amount,
    description,
    note,
    date,
    accountId,
    personKey,
    tagIds,
    paid,
    createTx,
  ];
}

/// The PUT of an entry edit: only what differs from [o]. [amountValue] and
/// [date] are the parsed form values; [sourced] = the entry came from a bill
/// (its transaction is not toggled here).
DebtEntryUpdate debtEntryUpdate(
  DebtEntryDraft o,
  DebtEntryDraft w, {
  required double amountValue,
  required DateTime date,
  required bool sourced,
  String? typedName,
}) {
  final txChange = w.createTx != o.createTx;
  return DebtEntryUpdate(
    direction: w.direction != o.direction ? w.direction : null,
    amount: w.amount != o.amount ? amountValue : null,
    date: w.date != o.date ? date : null,
    createTransaction: sourced ? null : w.createTx,
    accountId: w.createTx && (w.accountId != o.accountId || txChange)
        ? w.accountId
        : null,
    clearAccount:
        w.createTx && !txChange && o.accountId != null && w.accountId == null,
    description: w.description != o.description ? w.description.trim() : null,
    note: w.note != o.note ? w.note.trim() : null,
    paid: w.paid != o.paid ? w.paid : null,
    tagIds:
        w.createTx &&
            (w.tagIds.join() != o.tagIds.join() ||
                (txChange && w.tagIds.isNotEmpty))
        ? w.tagIds
        : null,
    key: w.personKey != o.personKey ? w.personKey : null,
    personName: w.personKey != o.personKey ? typedName : null,
    dueDate: w.due != o.due && w.due != null ? DateTime.parse(w.due!) : null,
    clearDueDate: w.due != o.due && w.due == null,
  );
}
