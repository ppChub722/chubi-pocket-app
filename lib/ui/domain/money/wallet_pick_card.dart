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
    this.muted = false,
    this.note,
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

  /// Nothing leaves this wallet (someone else paid it all): the card dims
  /// but stays tappable (owner 2026-10-21).
  final bool muted;

  /// In place of the balance line: "ไม่ออกจากกระเป๋า" / "−฿110 จาก ฿172".
  final String? note;

  double get _icon =>
      dense ? AvatarMetrics.sizeSmall : AvatarMetrics.sizeMedium;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final a = account;
    // No icon colour: the wallet's type colour, for the card and its icon.
    final accent = a?.iconCode.tintFor(palette, fallback: a.colorOf(context));
    Widget? icon;
    if (a != null) {
      icon = IconDisplay(
        type: IconType.account,
        size: _icon,
        iconCode: a.iconCode,
        fallbackColor: a.colorOf(context),
      );
      if (a.isShared) icon = SharedWalletIconBadge(size: _icon, child: icon);
    }
    final note = this.note;
    final card = PickCard(
      reserveSubtitle: true,
      label: label,
      value: a?.name,
      placeholder: placeholder,
      leading: icon ?? PickCardEmptyIcon(AppIcons.noWallet, size: _icon),
      subtitle: note != null
          ? Text(note, maxLines: 1, overflow: TextOverflow.ellipsis)
          : a == null || !a.showsBalance
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
    return muted ? Opacity(opacity: mutedOpacity, child: card) : card;
  }

  static const double mutedOpacity = 0.45;
}
