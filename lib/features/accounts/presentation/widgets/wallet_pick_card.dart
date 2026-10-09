import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import 'account_card.dart';

/// A wallet as a [PickCard], dressed like the wallet cards on the wallets
/// page once picked: the wallet's colour wash, its icon (+ the shared-wallet
/// badge), the balance in its accent colour and the type glyph faded in the
/// corner. Nothing picked → the dashed empty card.
class WalletPickCard extends StatelessWidget {
  const WalletPickCard({
    required this.account,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    super.key,
  });

  final Account? account;
  final String label;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final a = account;
    final accent = a?.iconCode?.accentColorFor(palette) ?? palette.primary;
    Widget? icon;
    if (a != null) {
      icon = IconDisplay(
        type: IconType.account,
        size: 40,
        iconCode: a.iconCode,
      );
      if (a.isShared) icon = SharedWalletIconBadge(size: 40, child: icon);
    }
    return PickCard(
      label: label,
      value: a?.name,
      placeholder: placeholder,
      leading: icon ?? const PickCardEmptyIcon(AppIcons.noWallet),
      subtitle: a == null
          ? null
          : MoneyText(
              a.balance,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
      accent: accent,
      watermark: a?.type.icon,
      onTap: onTap,
      errorText: errorText,
    );
  }
}
