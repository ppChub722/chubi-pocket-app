import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

bool typeCanJoinEvent(TransactionType type) => type != TransactionType.transfer;

bool _isSystemRow(Transaction t, Category? category) =>
    (t.category?.isSystem ?? false) || (category?.isSystem ?? false);

bool txCanJoinEvent(Transaction t, {Category? category}) =>
    t.canJoinEvent ??
    (typeCanJoinEvent(t.type) &&
        t.canEditCategory &&
        !t.isLocked &&
        !t.isDebtEntry &&
        !_isSystemRow(t, category));

bool txCanEditSplits(Transaction t, {Category? category}) =>
    t.canEditSplits ??
    (t.type != TransactionType.transfer &&
        t.canEditCategory &&
        !t.isLocked &&
        !_isSystemRow(t, category));
