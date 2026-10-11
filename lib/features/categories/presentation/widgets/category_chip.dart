import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';

/// A category as an [AppChip] — `[icon] name` in the category's colour
/// (owner 2026-10-11: one chip for the whole app). [selected] = the full
/// colour, otherwise a neutral outline (the icon keeps its colour). [all]
/// is the category list: L2 / L3 wear their top-level parent's icon, as
/// everywhere else.
AppChip categoryAppChip(
  BuildContext context,
  Category category, {
  required List<Category> all,
  bool selected = false,
  VoidCallback? onTap,
  PillSize size = PillSize.control,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final code = CategoryTree.resolveIconCode(category, all);
  return AppChip(
    label: categoryDisplayName(AppLocalizations.of(context)!, category),
    icon: IconRegistry.get(code?.icon, fallback: AppIcons.category),
    color: code?.accentColorFor(palette) ?? palette.primary,
    selected: selected,
    onTap: onTap,
    size: size,
  );
}
