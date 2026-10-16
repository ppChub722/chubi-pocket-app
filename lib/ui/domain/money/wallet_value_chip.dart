import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';

/// A wallet as a display chip (no tap) for `DetailRow.pick(valueChip:)` —
/// `[icon] name` in the wallet's own colour, same recipe as the category chip.
Widget walletValueChip(
  BuildContext context, {
  required String name,
  IconCode? iconCode,
}) {
  final palette = Theme.of(context).extension<PpForgeColors>()!;
  return PpForgeChip(
    label: name,
    icon: IconRegistry.get(iconCode?.icon, fallback: PpForgeIcons.wallet),
    color: iconCode.tintFor(palette),
    size: ChipSize.chip,
    maxWidth: 200,
  );
}
