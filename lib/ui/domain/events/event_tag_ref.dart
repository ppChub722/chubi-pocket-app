import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/chip_size.dart';
import '../icons/color_token.dart';
import '../icons/icon_code.dart';
import '../icons/icon_registry.dart';

class EventTagRef {
  const EventTagRef(this.name, {this.iconCode});

  final String name;
  final IconCode? iconCode;

  /// The tag's one colour: its icon colour (tags never show a bg), else the
  /// entity tint ([IconCodeTint.tintFor]), else primary.
  Color colorOf(AppColors palette) => (iconCode?.iconColors.isNotEmpty ?? false)
      ? resolveColor(iconCode!.iconColors.first, palette)
      : iconCode.tintFor(palette);

  Widget chip(BuildContext context, {VoidCallback? onTap, double? maxWidth}) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return AppChip(
      label: name,
      icon: IconRegistry.get(iconCode?.icon, fallback: AppIcons.tag),
      color: colorOf(palette),
      selected: true,
      onTap: onTap,
      size: ChipSize.mini,
      maxWidth: maxWidth,
    );
  }
}
