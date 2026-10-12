import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import '../icons/icon_code.dart';
import '../icons/icon_registry.dart';

/// A wallet as a display chip (no tap) for `DetailRow.pick(valueChip:)` —
/// `[icon] name` in the wallet's own colour, same recipe as the category chip.
Widget walletValueChip(
  BuildContext context, {
  required String name,
  IconCode? iconCode,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return AppChip(
    label: name,
    icon: IconRegistry.get(iconCode?.icon, fallback: AppIcons.wallet),
    color: iconCode.tintFor(palette),
    size: ChipSize.chip,
    maxWidth: 200,
  );
}
