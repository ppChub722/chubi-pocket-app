import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../ui/ui.dart';
import '../../domain/account.dart';

PpForgeCompactHeroCard walletCompactHero(
  BuildContext context,
  Account account, {
  VoidCallback? onTap,
}) {
  return PpForgeCompactHeroCard(
    style: accountHeroStyle(context, account),
    leading: AccountIconCircle(account: account, size: 28),
    title: PpForgeText(account.name, role: PpForgeTextRole.title),
    trailing: account.showsBalance
        ? MoneyText(
            accountDisplayBalance(account),
            symbol: context.readUserCurrencySymbol,
            style: PpForgeTypography.of(
              context,
              PpForgeTextRole.money,
            )?.copyWith(color: accountBalanceColor(context, account)),
          )
        : null,
    onTap: onTap,
  );
}
