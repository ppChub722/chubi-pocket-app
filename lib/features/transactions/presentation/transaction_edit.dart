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

/// Editing a saved transaction in place on its detail page: the checks and
/// the save. (A transfer's other wallet comes from the row's own
/// `transfer_peer` — no twin lookup.)

/// The rule the server would reject first; null = ready to save.
/// [splitsEditable]: the split editor is open — then the split must add up
/// (ฉัน + the people = what may be split, owner 2026-10-11).
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
    // An event bill: my splits share my part only (SPLITS_EXCEED_SHARE).
    if (total > c.splitCap + 0.005) {
      return c.eventOthers > 0 ? l.txSplitExceedsShare : l.txSplitExceeds;
    }
    if (splitsEditable && !c.splitsBalanced) return l.txSplitUnbalanced;
  }
  return null;
}

/// The split refusals of PUT /transactions/:id/splits in plain words;
/// null for anything else.
String? splitErrorMessage(AppLocalizations l, ApiException e) =>
    switch (e.code) {
      'SPLITS_EXCEED_AMOUNT' => l.txSplitExceeds,
      // An event bill: past what the other members leave me.
      'SPLITS_EXCEED_SHARE' => l.txSplitExceedsShare,
      'SPLIT_CONTACT_NOT_FOUND' ||
      'CONTACT_NOT_FOUND' ||
      'CONTACT_ARCHIVED' => l.txSplitErrorContact,
      'SPLITS_AUTHOR_ONLY' => l.txSplitAuthorOnly,
      _ => null,
    };

/// Split rows with a name but no amount (or the other way round) aren't
/// sent — say which before saving instead of dropping them silently
/// (owner 2026-10-10). True = go ahead.
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

/// Updates [t] with what changed in [c] in ONE `PUT /transactions/:id`
/// (tags ride in it; the split people go through their own PUT first or
/// last) and patches the wallet balances from the answer.
/// [initialAccountId] / [initialToAccountId] are the wallets as first
/// loaded (only a changed wallet is sent).
///
/// Returns a warning to show instead of "saved" (none today: the tags are
/// part of the one save); throws [ApiException] when the save failed.
Future<String?> saveTransactionEdit(
  BuildContext context, {
  required Transaction t,
  required DraftFormController c,
  required String? initialAccountId,
  required String? initialToAccountId,
}) async {
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

  // Splits (the author's expense / income only): the whole list goes up
  // when it changed. Lowering the amount: splits first, so the old total
  // never sits under the new amount (and the other way round).
  final repo = context.read<TransactionsRepository>();
  final splits = [
    for (final s in c.splits)
      if (s.isComplete) s.toUpdateJson(),
  ];
  final splitsBefore = [
    for (final s in t.splits) {'debt_id': s.debtId, 'owed_amount': s.amount},
  ];
  // A row with split_count but no people was edited from a list row — the
  // form never had its splits. PUT replaces the whole set, so sending
  // anything would wipe the real ones: leave them alone.
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
  // A transfer's tags live on its OUT row: the page edits that one.
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
    // The whole tag set replaces the row's.
    tagIds: c.tagIds.toList(),
  );
  // The answer carries every wallet the write touched (an old wallet too).
  accounts.patchBalances(result.accountBalances);
  if (!lowering && splitsChanged) {
    final row = await putSplits();
    // The split PUT's row (people, split_count) goes into the cache: no GET.
    if (row != null) txCubit.patchRow(row, afterWrite: true);
  }
  return null;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
