import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

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
