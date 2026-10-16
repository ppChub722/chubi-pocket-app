import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';

/// "ปรับยอด" bottom sheet (spec §2.5). The sheet itself is the kit's
/// [showAdjustBalanceFormSheet]; this wrapper maps the [Account] + l10n into
/// its plain params. Resolves the new balance + description + note (null
/// when blank), or null on cancel; the caller makes the API call
/// (`POST /v1/accounts/:id/adjust-balance`). The difference is booked as an
/// "ปรับยอด" transaction dated today.
Future<AdjustBalanceInput?> showAdjustBalanceSheet(
  BuildContext context,
  Account account,
) {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  final scheme = Theme.of(context).colorScheme;
  final credit = account.isLiability;
  return showAdjustBalanceFormSheet(
    context,
    name: account.name,
    balance: account.balance,
    symbol: context.readUserCurrencySymbol,
    tint: account.iconCode.tintFor(palette, fallback: scheme.primary),
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

/// What the ปรับยอด sheet resolves to.
typedef AdjustBalanceInput = AdjustBalanceSheetResult;

/// Turning "ติดตามยอดเงิน" back on: asks the wallet's balance once (the same
/// sheet, in its set-only form — no current / difference lines). Resolves the
/// balance as the BE stores it (a credit wallet's debt negative), or null on
/// cancel; the caller sends it as `current_balance` in the same update.
Future<double?> showSetBalanceSheet(
  BuildContext context,
  Account account,
) async {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  final scheme = Theme.of(context).colorScheme;
  final credit = account.isLiability;
  final result = await showAdjustBalanceFormSheet(
    context,
    name: account.name,
    balance: 0,
    symbol: context.readUserCurrencySymbol,
    tint: account.iconCode.tintFor(palette, fallback: scheme.primary),
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
