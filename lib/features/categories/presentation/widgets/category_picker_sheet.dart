import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../ui/ui.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
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
  List<CategoryPickerRow> rowsOf(List<Category> source) => [
    for (final c in source)
      if (!c.isSystem && c.type == type && !excludeIds.contains(c.id))
        CategoryPickerRow(
          id: c.id,
          name: c.name,
          parentId: c.parentId,
          sortOrder: c.sortOrder,
          iconCode: CategoryTree.resolveIconCode(c, source),
        ),
  ];
  CategoriesCubit? cache;
  try {
    cache = context.read<CategoriesCubit>();
  } catch (_) {
    cache = null; // no cache here (a test, the hub): the list as given
  }
  var latest = categories;
  final feed = cache == null
      ? null
      : CubitFeed<CategoriesState, List<CategoryPickerRow>>(cache, (s) {
          latest = s.categories;
          return rowsOf(latest);
        });
  Category? created;
  try {
    final choice = await showCategoryPicker(
      context,
      rows: rowsOf(categories),
      live: feed?.listenable,
      onRefresh: cache == null
          ? null
          : syncRefreshOf(context, const {SyncSet.categories}),
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
            : latest.where((c) => c.id == id).firstOrNull ??
                  categories.where((c) => c.id == id).firstOrNull;
        return hit == null ? null : CategoryPickerSelected(hit);
    }
  } finally {
    await feed?.dispose();
  }
}
