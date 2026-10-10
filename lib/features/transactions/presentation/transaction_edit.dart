import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../domain/transaction.dart';
import 'cubit/transactions_cubit.dart';
import 'widgets/draft_form.dart';

/// Editing a saved transaction — shared by the quick-create sheet's edit
/// mode and the transaction detail page's in-place edit, so both save the
/// same way.

/// A transfer's other row (same group) from the cache, if loaded.
Transaction? transferSibling(BuildContext context, Transaction t) {
  final group = t.transferGroupId;
  if (group == null) return null;
  return context
      .read<TransactionsCubit>()
      .state
      .transactions
      .where((x) => x.id != t.id && x.transferGroupId == group)
      .firstOrNull;
}

/// The wallet on a transfer's other side.
Account? transferOtherAccount(BuildContext context, Transaction t) {
  final id = transferSibling(context, t)?.accountId;
  return id == null ? null : context.read<AccountsCubit>().byId(id);
}

/// The rule the server would reject first; null = ready to save.
String? transactionEditProblem(AppLocalizations l, DraftFormController c) {
  if (c.amountValue <= 0) return l.quickAmountRequired;
  if (c.isTransfer) {
    if (c.account == null || c.toAccount == null) return l.txTransferNeedsTo;
    if (c.account!.id == c.toAccount!.id) return l.txTransferSameWallet;
  }
  return null;
}

/// Updates [t] with what changed in [c], then reconciles its tags and
/// reloads the wallets. [initialAccountId] / [initialToAccountId] are the
/// wallets as first loaded (only a changed wallet is sent).
///
/// Returns a warning when the row saved but its tags didn't; throws
/// [ApiException] when the save itself failed.
Future<String?> saveTransactionEdit(
  BuildContext context, {
  required Transaction t,
  required DraftFormController c,
  required String? initialAccountId,
  required String? initialToAccountId,
}) async {
  final l = AppLocalizations.of(context)!;
  final txCubit = context.read<TransactionsCubit>();
  final accounts = context.read<AccountsCubit>();
  final isTransfer = c.isTransfer;
  final description = c.description.text.trim().isEmpty
      ? null
      : c.description.text.trim();
  final note = c.note.text.trim().isEmpty ? null : c.note.text.trim();
  // Another member's row: never send category_id — only the author may
  // change it (403 CATEGORY_AUTHOR_ONLY otherwise).
  final canCategory = !isTransfer && t.canEditCategory;
  final accountId = c.account?.id;
  final accountChanged = accountId != initialAccountId;
  final toAccountChanged = isTransfer && c.toAccount?.id != initialToAccountId;

  final result = await txCubit.updateTransaction(
    id: t.id,
    amount: c.amountValue,
    date: _ymd(c.date),
    categoryId: canCategory ? c.category?.id : null,
    clearCategory: canCategory && t.categoryId != null && c.category == null,
    note: note,
    clearNote: note == null && t.note != null,
    description: description,
    clearDescription: description == null && t.description != null,
    accountId: accountChanged ? accountId : null,
    clearAccount: accountChanged && accountId == null,
    transferToAccountId: toAccountChanged ? c.toAccount?.id : null,
  );
  String? warn;
  // A transfer's tags live on its OUT row.
  final tagTarget = result.transfer != null
      ? result.transfer!.rows
            .firstWhere(
              (r) => r.signedAmount < 0,
              orElse: () => result.transfer!.rows.first,
            )
            .id
      : t.id;
  try {
    await txCubit.setTags(transactionId: tagTarget, tagIds: c.tagIds.toList());
  } on ApiException {
    warn = l.txSavedTagsFailed; // saved — just the tags
  }
  await accounts.load();
  return warn;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
