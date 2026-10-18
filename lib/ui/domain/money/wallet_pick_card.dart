import 'package:flutter/material.dart';

import '../../ui.dart';
import '../../../features/accounts/domain/account.dart';

class WalletPickCard extends StatelessWidget {
  const WalletPickCard({
    required this.account,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.dense = false,
    this.editable = false,
    this.onLongPress,
    super.key,
  });

  final Account? account;
  final String label;
  final String placeholder;
  final VoidCallback? onTap;
  final String? errorText;

  final bool editable;
  final VoidCallback? onLongPress;

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
      editable: editable,
      onLongPress: onLongPress,
      errorText: errorText,
      dense: dense,
    );
  }
}
