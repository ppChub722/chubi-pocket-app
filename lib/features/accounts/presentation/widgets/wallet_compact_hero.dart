import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../ui/ui.dart';
import '../../domain/account.dart';

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
