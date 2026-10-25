import 'package:flutter/material.dart';

import '../../../features/accounts/domain/account_type.dart';
import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import '../icons/icon_code.dart';
import '../icons/icon_registry.dart';
import '../icons/type_icon_default.dart';
import 'wallet_card.dart';

/// A wallet as a field's value: its icon + name in its own colour, its
/// [type]'s default until the user picks one.
Widget walletValueChip(
  BuildContext context, {
  required String name,
  IconCode? iconCode,
  AccountType? type,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final d = type?.iconDefault;
  return AppChip(
    label: name,
    icon: d == null
        ? IconRegistry.get(iconCode?.icon, fallback: AppIcons.wallet)
        : iconCode.glyphOr(d),
    color: d == null ? iconCode.tintFor(palette) : iconCode.tintOr(d, palette),
    size: ChipSize.chip,
    maxWidth: 200,
  );
}
