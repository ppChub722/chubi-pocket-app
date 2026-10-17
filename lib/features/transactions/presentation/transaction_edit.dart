import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../domain/transaction.dart';
import '../data/transactions_repository.dart';
import 'cubit/transactions_cubit.dart';
import 'widgets/draft_form.dart';

/// The rule the server would reject first; null = ready to save.
String? transactionEditProblem(
  AppLocalizations l,
  DraftFormController c, {
  bool splitsEditable = true,
}) {
  if (c.amountValue <= 0) return l.quickAmountRequired;
  if (c.isTransfer) {
    if (c.account == null || c.toAccount == null) return l.txTransferNeedsTo;
    if (c.account!.id == c.toAccount!.id) return l.txTransferSameWallet;
  }
  if (!c.isTransfer) {
    final total = c.splits
        .where((s) => s.isComplete)
        .fold<double>(0, (a, s) => a + (s.owedAmount ?? 0));
    if (total > c.splitCap + 0.005) {
      return c.eventOthers > 0 ? l.txSplitExceedsShare : l.txSplitExceeds;
    }
    if (splitsEditable && !c.splitsBalanced) return l.txSplitUnbalanced;
  }
  return null;
}

String? splitErrorMessage(AppLocalizations l, ApiException e) =>
    switch (e.code) {
      'SPLITS_EXCEED_AMOUNT' => l.txSplitExceeds,
      'SPLITS_EXCEED_SHARE' => l.txSplitExceedsShare,
      'SPLIT_CONTACT_NOT_FOUND' ||
      'CONTACT_NOT_FOUND' ||
      'CONTACT_ARCHIVED' => l.txSplitErrorContact,
      'SPLITS_AUTHOR_ONLY' => l.txSplitAuthorOnly,
      _ => null,
    };

Future<bool> confirmIncompleteSplits(
  BuildContext context,
  DraftFormController c,
) async {
  if (c.isTransfer) return true;
  final l = AppLocalizations.of(context)!;
  final half = [
    for (final s in c.splits)
      if (s.personName.trim().isNotEmpty != ((s.owedAmount ?? 0) > 0)) s,
  ];
  if (half.isEmpty) return true;
  final skip = await showChoiceDialog<bool>(
    context,
    title: l.txSplitIncompleteTitle,
    message: [
      for (final s in half)
        s.personName.trim().isEmpty
            ? l.txSplitIncompleteNoName(moneyString(context, s.owedAmount ?? 0))
            : l.txSplitIncompleteNoAmount(s.personName.trim()),
    ].join('\n'),
    choices: [
      DialogChoice(
        value: false,
        label: l.editKeepEditing,
        variant: AppButtonVariant.primary,
      ),
      DialogChoice(value: true, label: l.txSplitSkipIncomplete),
    ],
  );
  return skip ?? false;
}

Future<TransactionEditOutcome> saveTransactionEdit(
  BuildContext context, {
  required Transaction t,
  required DraftFormController c,
  required String? initialAccountId,
  required String? initialToAccountId,
  bool? alsoUpdateLink,
}) async {
  final txCubit = context.read<TransactionsCubit>();
  final accounts = context.read<AccountsCubit>();
  final isTransfer = c.isTransfer;
  final description = c.description.text.trim().isEmpty
      ? null
      : c.description.text.trim();
  final note = c.note.text.trim().isEmpty ? null : c.note.text.trim();
  // Another member's row: never send category_id — only the author may change
  // it (403 CATEGORY_AUTHOR_ONLY otherwise).
  final canCategory = !isTransfer && t.canEditCategory;
  final accountId = c.account?.id;
  final accountChanged = accountId != initialAccountId;
  final toAccountChanged = isTransfer && c.toAccount?.id != initialToAccountId;

  final repo = context.read<TransactionsRepository>();
  final splits = [
    for (final s in c.splits)
      if (s.isComplete) s.toUpdateJson(),
  ];
  final splitsBefore = [
    for (final s in t.splits) {'debt_id': s.debtId, 'owed_amount': s.amount},
  ];
  // A row with split_count but no people was edited from a list row — the form
  // never had its splits.
  final splitsLoaded = t.splitCount == 0 || t.splits.isNotEmpty;
  final splitsChanged =
      !isTransfer &&
      t.canEditCategory &&
      splitsLoaded &&
      jsonEncode(splits) != jsonEncode(splitsBefore);
  Future<Transaction?> putSplits() async {
    if (!splitsChanged) return null;
    return repo.updateSplits(t.id, splits);
  }

  final lowering = c.amountValue < t.amount;
  if (lowering) await putSplits();
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
    tagIds: c.tagIds.toList(),
    alsoUpdateLink: alsoUpdateLink,
  );
  if (result.isUpcoming) {
    accounts.patchBalances(result.accountBalances);
    return const TransactionEditOutcome(movedToUpcoming: true);
  }
  accounts.patchBalances(result.accountBalances);
  if (!lowering && splitsChanged) {
    final row = await putSplits();
    if (row != null) txCubit.patchRow(row, afterWrite: true);
  }
  return const TransactionEditOutcome();
}

class TransactionEditOutcome {
  const TransactionEditOutcome({this.warning, this.movedToUpcoming = false});

  /// Shown instead of "saved" (none today).
  final String? warning;

  final bool movedToUpcoming;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
