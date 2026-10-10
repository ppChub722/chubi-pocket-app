import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import 'account_card.dart';

/// `(icon) name  ฿12,345` — a wallet in one line: what the wallet page's
/// top bar says once its hero has scrolled away ([AppTopBar.titleSlot]).
/// The balance in the wallet's own colour; the name gives way first.
class WalletSummaryTitle extends StatelessWidget {
  const WalletSummaryTitle({required this.account, super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = account.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AccountIconCircle(account: account, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        MoneyText(
          account.balance,
          symbol: Currencies.symbolOf(account.currency),
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}
