import 'package:flutter/material.dart';

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
    symbol: Currencies.symbolOf(account.currency),
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
