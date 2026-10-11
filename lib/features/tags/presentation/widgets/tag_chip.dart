import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/color_token.dart';
import '../../../../shared/icon_maker/icon_code.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/tag.dart';

/// A tag's one colour — its icon tint (tags never show a bg / border, so a
/// stored bg colour must not win here). No colour → the theme primary.
Color tagColor(IconCode? code, AppColors palette) =>
    (code?.iconColors.isNotEmpty ?? false)
    ? resolveColor(code!.iconColors.first, palette)
    : palette.primary;

/// A tag as an [AppChip] — `[icon] name` in the tag's colour (owner
/// 2026-10-11: one chip for the whole app). [selected] null = a plain
/// display chip (the full colour, no ink), true = picked (the full colour),
/// false = a picker chip not picked (a neutral outline; the icon keeps its
/// colour). [size]: a detail page's display tags are [PillSize.chip], picker
/// rows [PillSize.control].
AppChip tagAppChip(
  BuildContext context,
  Tag tag, {
  bool? selected,
  VoidCallback? onTap,
  PillSize size = PillSize.control,
}) {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  return AppChip(
    label: tag.name.isEmpty ? l.tagFormNameLabel : tag.name,
    icon: IconRegistry.get(tag.iconCode?.icon, fallback: AppIcons.tag),
    color: tagColor(tag.iconCode, palette),
    selected: selected ?? true,
    onTap: onTap,
    size: size,
  );
}
