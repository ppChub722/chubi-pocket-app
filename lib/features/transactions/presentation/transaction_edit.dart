import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../domain/transaction.dart';
import 'cubit/transactions_cubit.dart';
import 'widgets/draft_form.dart';

/// The rule the server would reject first; null = ready to save.
/// [savedAmount]: the tx's stored amount. A 0 the system wrote (sync,
/// auto-create) saves as long as the amount wasn't touched (B1); a typed
/// amount stays > 0.
String? transactionEditProblem(
  AppLocalizations l,
  DraftFormController c, {
  bool splitsEditable = true,
  bool checkSplits = true,
  double? savedAmount,
}) {
  final untouchedZero = savedAmount == 0 && c.amountValue == 0;
  if (c.amountValue <= 0 && !untouchedZero) return l.quickAmountRequired;
  if (c.isTransfer) {
    if (c.account == null || c.toAccount == null) return l.txTransferNeedsTo;
    if (c.account!.id == c.toAccount!.id) return l.txTransferSameWallet;
  }
  // [checkSplits] false: another ผูกกับ tab is saved, the แบ่ง rows stay home.
  if (!c.isTransfer && checkSplits) {
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
        variant: PpForgeButtonVariant.primary,
      ),
      DialogChoice(value: true, label: l.txSplitSkipIncomplete),
    ],
  );
  return skip ?? false;
}

typedef TxEditBody = ({
  double amount,
  String date,
  String? categoryId,
  bool clearCategory,
  String? note,
  bool clearNote,
  String? description,
  bool clearDescription,
  String? accountId,
  bool clearAccount,
  String? transferToAccountId,
  List<String> tagIds,
  bool? alsoUpdateLink,
  Map<String, dynamic>? link,
  List<Map<String, dynamic>> splits,
  bool splitsChanged,
  bool lowering,
});

TxEditBody txEditBody(
  Transaction t,
  DraftFormController c, {
  required String? initialAccountId,
  required String? initialToAccountId,
  bool? alsoUpdateLink,
  Map<String, dynamic>? link,
}) {
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
  // A ผูกกับ tab switch (B3) carries its splits in [link], in the one PUT.
  final splitsChanged =
      link == null &&
      !isTransfer &&
      t.canEditCategory &&
      splitsLoaded &&
      jsonEncode(splits) != jsonEncode(splitsBefore);
  final amount = c.saveAmountFor(link == null ? null : c.pickedTab);
  return (
    amount: amount,
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
    link: link,
    splits: splits,
    splitsChanged: splitsChanged,
    lowering: amount < t.amount,
  );
}

Future<TransactionEditOutcome> saveTransactionEdit(
  BuildContext context, {
  required Transaction t,
  required DraftFormController c,
  required String? initialAccountId,
  required String? initialToAccountId,
  bool? alsoUpdateLink,
  Map<String, dynamic>? link,
}) async {
  final txCubit = context.read<TransactionsCubit>();
  final accounts = context.read<AccountsCubit>();
  final debts = DebtDirectoryCubit.maybeOf(context);
  final body = txEditBody(
    t,
    c,
    initialAccountId: initialAccountId,
    initialToAccountId: initialToAccountId,
    alsoUpdateLink: alsoUpdateLink,
    link: link,
  );
  // People on a row live on its bill now (paper model): no splits here.
  final result = await txCubit.updateTransaction(
    id: t.id,
    amount: body.amount,
    date: body.date,
    categoryId: body.categoryId,
    clearCategory: body.clearCategory,
    note: body.note,
    clearNote: body.clearNote,
    description: body.description,
    clearDescription: body.clearDescription,
    accountId: body.accountId,
    clearAccount: body.clearAccount,
    transferToAccountId: body.transferToAccountId,
    tagIds: body.tagIds,
    alsoUpdateLink: body.alsoUpdateLink,
    link: body.link,
  );
  accounts.patchBalances(result.accountBalances);
  // A repayment's edit moves the person's balance (0.4.0-3); a tab switch
  // moves everyone's in it.
  for (final b in [?result.personBalance, ...result.personBalances]) {
    debts?.applyBalance(b);
  }
  return const TransactionEditOutcome();
}

class TransactionEditOutcome {
  const TransactionEditOutcome({this.warning});

  /// Shown instead of "saved" (none today).
  final String? warning;
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
