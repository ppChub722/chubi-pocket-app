import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
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
    this.dense = false,
    super.key,
  });

  final Account? account;
  final String label;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  /// [PickCard.dense], with a smaller icon — two cards on one row.
  final bool dense;

  double get _icon =>
      dense ? AvatarMetrics.sizeSmall : AvatarMetrics.sizeMedium;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final a = account;
    final accent = a?.iconCode.tintFor(palette);
    Widget? icon;
    if (a != null) {
      icon = IconDisplay(
        type: IconType.account,
        size: _icon,
        iconCode: a.iconCode,
      );
      if (a.isShared) icon = SharedWalletIconBadge(size: _icon, child: icon);
    }
    return PickCard(
      reserveSubtitle: true,
      label: label,
      value: a?.name,
      placeholder: placeholder,
      leading: icon ?? PickCardEmptyIcon(AppIcons.noWallet, size: _icon),
      subtitle: a == null || !a.showsBalance
          ? null
          : MoneyText(
              a.balance,
              style: AppTypography.of(
                context,
                AppTextRole.money,
              )?.copyWith(color: accent),
            ),
      accent: accent,
      watermark: a?.type.icon,
      onTap: onTap,
      errorText: errorText,
      dense: dense,
    );
  }
}
