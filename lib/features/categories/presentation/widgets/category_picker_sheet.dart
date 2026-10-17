import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../pages/category_detail_page.dart';

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
