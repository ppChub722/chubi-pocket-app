import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../category_label.dart';

/// A server [CategoryPathItem] list (root -> ... -> last) as a [ChipPath],
/// each step with its OWN icon + colour from the item's `icon_code` — no
/// category list needed.
Widget categoryPathItemsChipPath(
  BuildContext context,
  List<CategoryPathItem> items,
) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return ChipPath(
    segments: [
      for (final p in items)
        ChipPathSegment(
          label: p.name,
          icon: IconRegistry.get(p.iconCode?.icon, fallback: AppIcons.category),
          color: p.iconCode.tintFor(palette),
        ),
    ],
  );
}

/// A category (+ its ancestors root -> parent) as a [ChipPath] value for
/// `DetailRow.pick(valueChip:)` — every segment has its OWN icon + colour.
/// Ancestors come from [Category.path]; their icons are looked up in [all]
/// (falling back to the root's icon when a level has none).
Widget categoryChipPath(
  BuildContext context,
  Category category, {
  required List<Category> all,
}) {
  final palette = Theme.of(context).extension<AppColors>()!;
  final l = AppLocalizations.of(context)!;

  ChipPathSegment segment(String label, Category? c) {
    final code = c == null ? null : CategoryTree.resolveIconCode(c, all);
    return ChipPathSegment(
      label: label,
      icon: IconRegistry.get(code?.icon, fallback: AppIcons.category),
      color: code.tintFor(palette),
    );
  }

  Category? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  return ChipPath(
    segments: [
      for (final p in category.path) segment(p.name, byId(p.id)),
      segment(categoryDisplayName(l, category), category),
    ],
  );
}
