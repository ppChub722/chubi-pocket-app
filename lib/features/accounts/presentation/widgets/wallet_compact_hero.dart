import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../ui/ui.dart';
import '../../domain/account.dart';
import 'account_card.dart';

/// The wallet page's [CompactHeroBar] (owner 2026-10-11): `(icon) name
/// balance` — the balance in the wallet's balance colour (the liability
/// token for a credit card / pay later, else its own icon colour) and never
/// "-฿0.00".
CompactHeroBar walletCompactHero(
  BuildContext context,
  Account account, {
  VoidCallback? onTap,
}) {
  return CompactHeroBar(
    style: accountHeroStyle(context, account),
    leading: AccountIconCircle(account: account, size: 28),
    title: AppText(account.name, role: AppTextRole.title),
    trailing: account.showsBalance
        ? MoneyText(
            accountDisplayBalance(account),
            symbol: context.readUserCurrencySymbol,
            style: AppTypography.of(
              context,
              AppTextRole.money,
            )?.copyWith(color: accountBalanceColor(context, account)),
          )
        : null,
    onTap: onTap,
  );
}
