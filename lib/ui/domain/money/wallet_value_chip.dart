import 'package:flutter/material.dart';

import '../../../features/accounts/domain/account_type.dart';
import '../tokens/app_icons.dart';
import 'package:pp_forge_core/ui.dart';
import '../icons/type_icon_default.dart';
import 'wallet_card.dart';

/// A wallet as a field's value: its icon + name in its own colour, its
/// [type]'s default until the user picks one.
Widget walletValueChip(
  BuildContext context, {
  required String name,
  PpForgeIconCode? iconCode,
  AccountType? type,
}) {
  final palette = Theme.of(context).extension<PpForgeColors>()!;
  final d = type?.iconDefault;
  return PpForgeChip(
    label: name,
    icon: d == null
        ? PpForgeIconRegistry.get(iconCode?.icon, fallback: AppIcons.wallet)
        : iconCode.glyphOr(d),
    color: d == null ? iconCode.tintFor(palette) : iconCode.tintOr(d, palette),
    size: ChipSize.chip,
    maxWidth: 200,
  );
}
