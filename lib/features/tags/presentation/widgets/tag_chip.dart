import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/tag.dart';

/// A tag's one colour — its icon tint (tags never show a bg / border, so a
/// stored bg colour must not win here).
Color tagColor(IconCode? code, AppColors palette) =>
    (code?.iconColors.isNotEmpty ?? false)
    ? resolveColor(code!.iconColors.first, palette)
    : palette.primary;

AppChip tagAppChip(
  BuildContext context,
  Tag tag, {
  bool? selected,
  VoidCallback? onTap,
  VoidCallback? onRemove,
  ChipSize size = ChipSize.control,
}) {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  return AppChip(
    label: tag.name.isEmpty ? l.tagFormNameLabel : tag.name,
    icon: IconRegistry.get(tag.iconCode?.icon, fallback: AppIcons.tag),
    color: tagColor(tag.iconCode, palette),
    selected: selected ?? true,
    onTap: onTap,
    trailing: onRemove == null ? AppChipTrailing.none : AppChipTrailing.remove,
    onRemove: onRemove,
    removeOnly: onRemove != null,
    size: size,
  );
}
