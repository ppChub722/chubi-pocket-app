import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';

PpForgeChip categoryAppChip(
  BuildContext context,
  Category category, {
  required List<Category> all,
  bool selected = false,
  VoidCallback? onTap,
  bool dashed = false,
  ChipSize size = ChipSize.control,
}) {
  final palette = Theme.of(context).extension<PpForgeColors>()!;
  final code = CategoryTree.resolveIconCode(category, all);
  return PpForgeChip(
    label: categoryDisplayName(AppLocalizations.of(context)!, category),
    icon: PpForgeIconRegistry.get(code?.icon, fallback: AppIcons.category),
    color: code.tintFor(palette),
    selected: selected,
    onTap: onTap,
    dashed: dashed,
    inset: dashed && selected,
    size: size,
  );
}
