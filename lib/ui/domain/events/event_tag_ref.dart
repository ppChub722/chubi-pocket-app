import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import 'package:pp_forge_core/ui.dart';

class EventTagRef {
  const EventTagRef(this.name, {this.iconCode});

  final String name;
  final PpForgeIconCode? iconCode;

  /// The tag's one colour: its icon colour (tags never show a bg), else the
  /// entity tint ([PpForgeIconCodeTint.tintFor]), else primary.
  Color colorOf(PpForgeColors palette) => (iconCode?.iconColors.isNotEmpty ?? false)
      ? ppForgeResolveColor(iconCode!.iconColors.first, palette)
      : iconCode.tintFor(palette);

  Widget chip(BuildContext context, {VoidCallback? onTap, double? maxWidth}) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return PpForgeChip(
      label: name,
      icon: PpForgeIconRegistry.get(iconCode?.icon, fallback: AppIcons.tag),
      color: colorOf(palette),
      selected: true,
      onTap: onTap,
      size: ChipSize.mini,
      maxWidth: maxWidth,
    );
  }
}
