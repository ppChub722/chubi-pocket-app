import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../pages/category_detail_page.dart';

/// Result returned by [showCategoryPickerSheet]. Distinct from `null`
/// (which means "user dismissed without picking") — `cleared` means
/// "user explicitly chose the None option".
sealed class CategoryPickerResult {
  const CategoryPickerResult();
}

class CategoryPickerSelected extends CategoryPickerResult {
  const CategoryPickerSelected(this.category);
  final Category category;
}

class CategoryPickerCleared extends CategoryPickerResult {
  const CategoryPickerCleared();
}

/// Shared category-tree picker — a THIN WRAPPER over the presentational
/// organism `showCategoryPicker` (lib/ui/domain/pickers): maps the
/// [Category] models + l10n strings to its plain rows / labels and the
/// result back to a [CategoryPickerResult].
///
/// Reusable across features via arguments:
/// - [maxDepth] — deepest level (0-based: L1=0, L2=1, L3=2) that is shown
///   **and** selectable. Quick-create picks any of 3 levels (`maxDepth: 2`);
///   the category-parent picker only allows L1/L2 (`maxDepth: 1`) because a
///   child of the picked parent must stay within 3 levels.
/// - [excludeIds] — rows (and their whole subtree) to hide. The parent
///   picker passes the edited category + its descendants so you can't pick
///   yourself or create a cycle.
/// - [allowNone] / [noneLabel] — show a "None" row (clear / top-level).
/// - [title] — sheet heading (default "เลือกหมวดหมู่").
/// - [allowCreate] — a "＋ เพิ่มหมวดหมู่" row: opens the create page over the
///   sheet; saving there picks the new category and closes the picker, back
///   returns to the picker (owner 2026-10-10).
///
/// System categories are always filtered out (server auto-assigns them).
Future<CategoryPickerResult?> showCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  required CategoryType type,
  Category? selected,
  bool allowNone = true,
  String? title,
  String? noneLabel,
  int maxDepth = 2,
  Set<String> excludeIds = const <String>{},
  bool allowCreate = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final pool = categories
      .where((c) => !c.isSystem && c.type == type && !excludeIds.contains(c.id))
      .toList();
  Category? created;
  final choice = await showCategoryPicker(
    context,
    rows: [
      for (final c in pool)
        CategoryPickerRow(
          id: c.id,
          name: c.name,
          parentId: c.parentId,
          sortOrder: c.sortOrder,
          iconCode: CategoryTree.resolveIconCode(c, categories),
        ),
    ],
    labels: CategoryPickerLabels(
      title: title ?? l.categoryPickerTitle,
      searchHint: l.categoryPickerSearchHint,
      none: noneLabel ?? l.transactionFormCategoryPickerNoneOption,
      addNew: l.categoriesAddNew,
      empty: l.transactionFormCategoryPickerEmpty,
      noMatch: l.categoryPickerNoMatch,
    ),
    selectedId: selected?.id,
    allowNone: allowNone,
    maxDepth: maxDepth,
    // The create page, pushed over the sheet. Saving there pops with the
    // new category -> pick it; back (nothing saved) returns to the picker.
    onCreate: allowCreate
        ? () async {
            created = await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<Category>(
                builder: (_) =>
                    CategoryDetailPage(initialType: type, popOnCreate: true),
              ),
            );
            return created?.id;
          }
        : null,
  );
  switch (choice) {
    case null:
      return null;
    case CategoryPickerNone():
      return const CategoryPickerCleared();
    case CategoryPickerPicked(:final id):
      final hit = created?.id == id
          ? created
          : categories.where((c) => c.id == id).firstOrNull;
      return hit == null ? null : CategoryPickerSelected(hit);
  }
}
