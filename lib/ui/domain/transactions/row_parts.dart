import 'package:flutter/material.dart';

import '../../../features/accounts/domain/account_type.dart';
import '../../molecules/app_list_row.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/color_contrast.dart';
import '../icons/color_token.dart';
import '../icons/icon_code.dart';
import '../icons/icon_registry.dart';
import '../icons/icon_type.dart';
import '../icons/type_icon_default.dart';
import '../money/wallet_card.dart';

/// A wallet on an [AppListRow]: its icon and name in the wallet's own colour
/// (its [type]'s default until the user picks one), no fill, no border; muted
/// with no wallet.
ListRowChip walletRowChip(
  BuildContext context, {
  required String name,
  IconCode? iconCode,
  AccountType? type,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final surface = Theme.of(context).colorScheme.surface;
  final code = type == null ? iconCode : iconCode.orDefault(type.iconDefault);
  final own = code == null
      ? null
      : code.background != null
      ? code.bgColorFor(palette)
      : code.iconColors.isEmpty
      ? null
      : resolveColor(code.iconColors.first, palette);
  return ListRowChip(
    name,
    icon: code == null
        ? AppIcons.noWallet
        : IconRegistry.get(code.icon, fallback: IconType.account.fallbackIcon),
    color: own == null ? null : ensureContrast(own, surface),
    bare: true,
  );
}

/// "#name" in the tag's icon colour, for [ListRowLine.spans].
InlineSpan tagSpan(BuildContext context, String name, {IconCode? iconCode}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final colors = iconCode?.iconColors ?? const [];
  return TextSpan(
    text: '#$name',
    style: TextStyle(
      color: colors.isEmpty
          ? palette.primary
          : resolveColor(colors.first, palette),
      fontWeight: FontWeight.w600,
    ),
  );
}
