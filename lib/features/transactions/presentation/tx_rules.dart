import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

// What a transaction row may do — the one place these rules live. The BE's
// capability flags win when it sends them (can_join_event,
// can_edit_splits); a BE that doesn't yet falls back to the FE's own
// reading of the row. [category] tells system rows apart (opening
// balance, adjustment, repayment — reserved icons; system_kind isn't on
// the wire).

/// Can a row of [type] go into an event at all? Not a transfer. (A new
/// row, in the quick create — no flags yet.)
bool typeCanJoinEvent(TransactionType type) => type != TransactionType.transfer;

/// Can [t] join / move to / leave an event here: [Transaction.canJoinEvent]
/// when sent, else — my own expense / income, not locked, not a debt
/// repayment, not a system category.
bool txCanJoinEvent(Transaction t, {Category? category}) =>
    t.canJoinEvent ??
    (typeCanJoinEvent(t.type) &&
        t.canEditCategory &&
        !t.isLocked &&
        t.sourcePersonalDebtId == null &&
        !(category?.isSystem ?? false));

/// Does [t] get the split editor: [Transaction.canEditSplits] when sent,
/// else — my own (author) expense / income, not locked, not a system
/// category.
bool txCanEditSplits(Transaction t, {Category? category}) =>
    t.canEditSplits ??
    (t.type != TransactionType.transfer &&
        t.canEditCategory &&
        !t.isLocked &&
        !(category?.isSystem ?? false));
