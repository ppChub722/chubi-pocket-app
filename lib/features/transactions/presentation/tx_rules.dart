import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

// What a transaction row may do — the one place these rules live. The BE's
// capability flags win when it sends them (can_join_event,
// can_edit_splits); a BE that doesn't yet falls back to the FE's own
// reading of the row. The row's embedded category (is_system) and its
// debt link (counterparty) tell system rows apart; the optional [category] is an
// extra hint (e.g. the category picked in a form).

/// Can a row of [type] go into an event at all? Not a transfer. (A new
/// row, in the quick create — no flags yet.)
bool typeCanJoinEvent(TransactionType type) => type != TransactionType.transfer;

/// Is [t] on a system category (opening balance, adjustment, repayment…)?
bool _isSystemRow(Transaction t, Category? category) =>
    (t.category?.isSystem ?? false) || (category?.isSystem ?? false);

/// Can [t] join / move to / leave an event here: [Transaction.canJoinEvent]
/// when sent, else — my own expense / income, not locked, not a debt
/// repayment, not a system category.
bool txCanJoinEvent(Transaction t, {Category? category}) =>
    t.canJoinEvent ??
    (typeCanJoinEvent(t.type) &&
        t.canEditCategory &&
        !t.isLocked &&
        !t.isDebtEntry &&
        !_isSystemRow(t, category));

/// Does [t] get the split editor: [Transaction.canEditSplits] when sent,
/// else — my own (author) expense / income, not locked, not a system
/// category.
bool txCanEditSplits(Transaction t, {Category? category}) =>
    t.canEditSplits ??
    (t.type != TransactionType.transfer &&
        t.canEditCategory &&
        !t.isLocked &&
        !_isSystemRow(t, category));
