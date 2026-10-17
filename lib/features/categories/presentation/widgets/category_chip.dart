import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';

/// A category as an [AppChip] — `[icon] name` in the category's colour
/// (owner 2026-10-11: one chip for the whole app). [selected] = the full
/// colour, otherwise a neutral outline (the icon keeps its colour). [all]
/// is the category list: L2 / L3 wear their top-level parent's icon, as
/// everywhere else. [dashed]: the chip is in an edit form, so it is
/// changeable (see [AppChip.dashed]).
AppChip categoryAppChip(
  BuildContext context,
  Category category, {
  required List<Category> all,
  bool selected = false,
  VoidCallback? onTap,
  bool dashed = false,
  ChipSize size = ChipSize.control,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final code = CategoryTree.resolveIconCode(category, all);
  return AppChip(
    label: categoryDisplayName(AppLocalizations.of(context)!, category),
    icon: IconRegistry.get(code?.icon, fallback: AppIcons.category),
    color: code.tintFor(palette),
    selected: selected,
    onTap: onTap,
    // In an edit form: dashed = changeable; chosen + changeable = inset line.
    dashed: dashed,
    inset: dashed && selected,
    size: size,
  );
}
