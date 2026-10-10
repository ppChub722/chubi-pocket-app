import 'package:flutter/material.dart';

import '../../../../core/constants/currencies.dart';
import '../../../../shared/widgets/ui.dart';
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
    leading: AccountIconCircle(account: account, size: 28),
    title: Text(account.name),
    trailing: MoneyText(
      accountDisplayBalance(account),
      symbol: Currencies.symbolOf(account.currency),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: accountBalanceColor(context, account),
      ),
    ),
    onTap: onTap,
  );
}
