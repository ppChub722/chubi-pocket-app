import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../event_errors.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/domain/debt_ledger.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../domain/project.dart';

Future<bool> showResolveSheet(
  BuildContext context, {
  required ProjectTransaction tx,
  required bool isParent,
  required double childrenTotal,
  required String myMemberId,
  ProjectMember? counterparty,
}) {
  final l = AppLocalizations.of(context)!;
  final accounts = context.read<AccountsCubit>();
  final categories = context.read<CategoriesCubit>();
  final txRepo = context.read<TransactionsRepository>();
  final debtsRepo = context.read<PersonalDebtsRepository>();
  if (accounts.state.accounts.isEmpty) accounts.load();
  categories.loadIfNeeded();

  final symbol = context.readUserCurrencySymbol;
  final name = counterparty?.displayName ?? '?';
  final iAmDebtor = tx.transactionMemberId == myMemberId;
  final share = tx.amount - childrenTotal;
  final hasShare = isParent && childrenTotal > 0;

  final txType = isParent
      ? (tx.type == 'expense'
            ? TransactionType.expense
            : TransactionType.income)
      : (iAmDebtor ? TransactionType.expense : TransactionType.income);

  double amountFor(bool shareOnly) {
    if (isParent && shareOnly) return share < 0 ? 0 : share;
    return tx.amount;
  }

  return showEventResolveSheet(
    context,
    labels: EventResolveLabels(
      title: l.projectTxResolve,
      confirm: l.projectResolveConfirm,
      amount: l.projectResolveAmount,
      shareOnly: l.projectResolveShareOnly,
      account: l.debtSettleAccount,
      accountEmpty: l.quickEventNone,
      accountRequired: l.debtSettleAccountRequired,
      category: l.projectResolveCategory,
      categoryEmpty: l.projectResolveCategoryNone,
      asTransaction: l.projectResolveAsTx,
      asDebt: l.projectResolveAsDebt,
      debtRow: iAmDebtor ? l.debtYouOwe(name) : l.debtTheyOweYou(name),
      debtHint: l.projectResolveDebtHint,
    ),
    amount: tx.amount,
    currencySymbol: symbol,
    shareAmount: hasShare ? (share < 0 ? 0 : share) : null,
    shareHint: hasShare
        ? l.projectResolveShareHint(
            moneyString(context, tx.amount, symbol: symbol),
            moneyString(context, share, symbol: symbol),
          )
        : null,
    showModeTabs: !isParent,
    onPickAccount: (current) async {
      final r = await showAccountPickerSheet(
        context: context,
        accounts: accounts.state.accounts,
        selected: current?.ref as Account?,
        title: l.debtSettleAccount,
      );
      if (r is! AccountPickerSelected || !context.mounted) return null;
      final a = r.account;
      return ResolvePickResult(
        ResolvePickValue(
          label: a.name,
          icon: a.type.icon,
          color: a.colorOf(context),
          ref: a,
        ),
      );
    },
    onPickCategory: (current) async {
      final r = await showCategoryPickerSheet(
        context: context,
        categories: categories.state.categories,
        selected: current?.ref as Category?,
        type: txType == TransactionType.expense
            ? CategoryType.expense
            : CategoryType.income,
        allowNone: true,
        noneLabel: l.projectResolveCategoryNone,
        title: l.projectResolveCategory,
      );
      if (r is CategoryPickerSelected) {
        return ResolvePickResult(
          ResolvePickValue(label: r.category.name, ref: r.category),
        );
      }
      if (r is CategoryPickerCleared) return const ResolvePickResult(null);
      return null;
    },
    onSubmit: (res) async {
      try {
        final amount = amountFor(res.shareOnly);
        if (res.mode == EventResolveMode.asTransaction) {
          final account = res.account!.ref! as Account;
          final category = res.category?.ref as Category?;
          final created = await txRepo.create(
            type: txType,
            accountId: account.id,
            amount: amount,
            date: tx.date,
            description: tx.description,
            note: tx.note,
            categoryId: category?.id,
            sourceProjectTransactionId: tx.id,
          );
          accounts.patchBalances(created.accountBalances);
        } else {
          await debtsRepo.createEntry(
            debtPersonKey(name: name),
            direction: iAmDebtor
                ? DebtEntryDirection.received
                : DebtEntryDirection.paid,
            amount: amount,
            description: tx.description,
            note: tx.note,
            personName: name,
          );
        }
        return true;
      } on ApiException catch (e) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            eventErrorText(AppLocalizations.of(context)!, e),
            tone: Tone.danger,
          );
        }
        return false;
      }
    },
  );
}
