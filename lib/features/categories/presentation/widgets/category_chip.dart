import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';

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
    dashed: dashed,
    inset: dashed && selected,
    size: size,
  );
}
