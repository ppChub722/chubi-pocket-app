import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';

Future<AdjustBalanceInput?> showAdjustBalanceSheet(
  BuildContext context,
  Account account,
) {
  final l = AppLocalizations.of(context)!;
  final credit = account.isLiability;
  return showAdjustBalanceFormSheet(
    context,
    name: account.name,
    balance: account.balance,
    symbol: context.readUserCurrencySymbol,
    tint: account.colorOf(context),
    isCredit: credit,
    strings: AdjustBalanceStrings(
      title: l.accountAdjustBalanceTitle,
      primaryLabel: l.accountDetailAdjustBalance,
      currentLabel: l.accountAdjustBalanceCurrentLabel,
      newLabel: credit
          ? l.accountAdjustBalanceNewDebtLabel
          : l.accountAdjustBalanceNewLabel,
      diffLabel: l.accountAdjustBalanceDiffLabel,
      descriptionLabel: l.commonDescription,
      noteLabel: l.commonNote,
      noChange: l.accountAdjustBalanceNoChange,
      willCreate: l.accountAdjustBalanceWillCreate,
    ),
  );
}

typedef AdjustBalanceInput = AdjustBalanceSheetResult;

Future<double?> showSetBalanceSheet(
  BuildContext context,
  Account account,
) async {
  final l = AppLocalizations.of(context)!;
  final credit = account.isLiability;
  final result = await showAdjustBalanceFormSheet(
    context,
    name: account.name,
    balance: 0,
    symbol: context.readUserCurrencySymbol,
    tint: account.colorOf(context),
    isCredit: credit,
    setOnly: true,
    strings: AdjustBalanceStrings(
      title: l.walletTrackSetBalanceTitle,
      primaryLabel: l.walletTrackSetBalanceAction,
      currentLabel: l.accountAdjustBalanceCurrentLabel,
      newLabel: credit
          ? l.accountAdjustBalanceNewDebtLabel
          : l.accountAdjustBalanceNewLabel,
      diffLabel: l.accountAdjustBalanceDiffLabel,
      descriptionLabel: l.commonDescription,
      noteLabel: l.commonNote,
      noChange: l.accountAdjustBalanceNoChange,
      willCreate: l.accountAdjustBalanceWillCreate,
    ),
  );
  return result?.balance;
}
