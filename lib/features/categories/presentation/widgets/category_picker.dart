import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/cubit_feed.dart';
import '../../../../core/data/sync_refresh.dart';
import '../../../../core/data/sync_set.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/category.dart';
import '../../domain/category_tree.dart';
import '../../domain/category_type.dart';
import '../cubit/categories_cubit.dart';
import '../pages/category_detail_page.dart';

sealed class CategoryPick {
  const CategoryPick();
}

class CategoryPicked extends CategoryPick {
  const CategoryPicked(this.category);
  final Category category;
}

/// "ไม่ระบุหมวด" was picked.
class CategoryPickedNone extends CategoryPick {
  const CategoryPickedNone();
}

class CategoryPicks {
  const CategoryPicks({
    this.categories = const [],
    this.ids = const [],
    this.withChildren = const {},
    this.none = false,
  });

  final List<Category> categories;

  /// Every ticked id in order, also one no longer in the cache (it stays
  /// picked; the caller can name it from what it had).
  final List<String> ids;

  /// The ticked ids that also take in all their sub-categories.
  final Set<String> withChildren;

  /// "ไม่ระบุหมวด" is ticked.
  final bool none;
}

/// The category picker every page opens: [one] or [many], of one type or both
/// (then with tabs ทั้งหมด / รายจ่าย / รายรับ and a heading per type).
/// [categories] = the list to start from; without it the categories cache.
abstract final class CategoryPicker {
  static const _both = {CategoryType.expense, CategoryType.income};

  static Future<CategoryPick?> one(
    BuildContext context, {
    Set<CategoryType> types = _both,
    CategoryType? initialType,
    String? selectedId,
    bool allowNone = false,
    String? noneLabel,
    bool allowCreate = false,
    String? title,
    Set<String> excludeIds = const {},
    int maxDepth = 2,
    List<Category>? categories,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: false,
      types: types,
      initialType: initialType,
      selected: {?selectedId},
      allowNone: allowNone,
      noneLabel: noneLabel,
      allowCreate: allowCreate,
      title: title,
      excludeIds: excludeIds,
      maxDepth: maxDepth,
      categories: categories,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    if (r.result.none) return const CategoryPickedNone();
    final hit = r.lookup(r.result.id);
    return hit == null ? null : CategoryPicked(hit);
  }

  static Future<CategoryPicks?> many(
    BuildContext context, {
    Set<CategoryType> types = _both,
    CategoryType? initialType,
    Set<String> selected = const {},
    Set<String> selectedWithChildren = const {},
    PickerChildren children = PickerChildren.toggle,
    bool allowNone = false,
    bool noneSelected = false,
    String? title,
    List<Category>? categories,
    bool useRootNavigator = true,
  }) async {
    final r = await _open(
      context,
      multi: true,
      types: types,
      initialType: initialType,
      selected: selected,
      selectedWithChildren: selectedWithChildren,
      children: children,
      allowNone: allowNone,
      noneSelected: noneSelected,
      title: title,
      categories: categories,
      useRootNavigator: useRootNavigator,
    );
    if (r == null) return null;
    return CategoryPicks(
      categories: [for (final id in r.result.ids) ?r.lookup(id)],
      ids: r.result.ids,
      withChildren: r.result.withChildren,
      none: r.result.none,
    );
  }

  static Future<_Opened?> _open(
    BuildContext context, {
    required bool multi,
    required Set<CategoryType> types,
    CategoryType? initialType,
    Set<String> selected = const {},
    Set<String> selectedWithChildren = const {},
    PickerChildren children = PickerChildren.separate,
    bool allowNone = false,
    bool noneSelected = false,
    String? noneLabel,
    bool allowCreate = false,
    String? title,
    Set<String> excludeIds = const {},
    int maxDepth = 2,
    List<Category>? categories,
    bool useRootNavigator = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    CategoriesCubit? cache;
    try {
      cache = context.read<CategoriesCubit>();
    } catch (_) {
      cache = null;
    }
    var latest = categories ?? cache?.state.categories ?? const <Category>[];
    final start = latest;
    List<PickerItem> itemsOf(List<Category> all) =>
        _items(all, types: types, excludeIds: excludeIds);
    final feed = cache == null
        ? null
        : CubitFeed<CategoriesState, PickerData>(cache, (s) {
            latest = s.categories;
            return PickerData(
              itemsOf(latest),
              loading: s.status == CategoriesStatus.loading,
              error: s.error,
            );
          });
    final both = types.length > 1;
    final order = _typeOrder.where(types.contains).toList();
    Category? created;
    try {
      final result = await showItemPicker(
        context,
        useRootNavigator: useRootNavigator,
        ItemPickerSheet(
          title: title ?? l.categoryPickerTitle,
          items: itemsOf(latest),
          live: feed?.listenable,
          onRefresh: cache == null
              ? null
              : syncRefreshOf(context, const {SyncSet.categories}),
          multi: multi,
          selected: selected,
          selectedWithChildren: selectedWithChildren,
          noneSelected: noneSelected,
          children: children,
          includeChildrenLabel: l.multiPickIncludeChildren,
          maxDepth: maxDepth,
          groups: both
              ? [for (final t in order) PickerGroup(t.name, _typeLabel(l, t))]
              : const [],
          filters: both
              ? [
                  PickerFilter(l.transactionsListFilterAll, (_) => true),
                  for (final t in order)
                    PickerFilter(_typeLabel(l, t), (i) => i.group == t.name),
                ]
              : const [],
          initialFilter: both && initialType != null
              ? order.indexOf(initialType) + 1
              : 0,
          none: allowNone
              ? PickerNone(
                  label: noneLabel ?? l.transactionFormCategoryPickerNoneOption,
                  icon: AppIcons.noCategory,
                )
              : null,
          create: allowCreate
              ? PickerCreate(
                  label: (_) => l.categoriesAddNew,
                  onCreate: (_) async {
                    created = await Navigator.of(context, rootNavigator: true)
                        .push(
                          MaterialPageRoute<Category>(
                            builder: (_) => CategoryDetailPage(
                              initialType:
                                  initialType ??
                                  (both ? CategoryType.expense : types.first),
                              popOnCreate: true,
                            ),
                          ),
                        );
                    return created?.id;
                  },
                )
              : null,
          searchable: true,
          searchHint: l.categoryPickerSearchHint,
          emptyText: l.transactionFormCategoryPickerEmpty,
          noMatchText: l.categoryPickerNoMatch,
          confirmLabel: multi
              ? (n) => n == 0 ? l.commonOk : l.multiPickConfirm(n)
              : null,
        ),
      );
      if (result == null) return null;
      Category? lookup(String? id) {
        if (id == null) return null;
        if (created?.id == id) return created;
        return latest.where((c) => c.id == id).firstOrNull ??
            start.where((c) => c.id == id).firstOrNull;
      }

      return _Opened(result, lookup);
    } finally {
      unawaited(feed?.dispose());
    }
  }

  static const _typeOrder = [CategoryType.expense, CategoryType.income];

  static String _typeLabel(AppLocalizations l, CategoryType t) =>
      t == CategoryType.income
      ? l.transactionTypeIncome
      : l.transactionTypeExpense;

  /// Expense before income, each in its own order; a sub-category keeps its
  /// parent's type, so the tree never crosses a group.
  static List<PickerItem> _items(
    List<Category> all, {
    required Set<CategoryType> types,
    required Set<String> excludeIds,
  }) {
    final pool = [
      for (final c in all)
        if (!c.isSystem && types.contains(c.type) && !excludeIds.contains(c.id))
          c,
    ];
    int typeRank(Category c) => _typeOrder.indexOf(c.type);
    pool.sort((a, b) {
      final t = typeRank(a).compareTo(typeRank(b));
      return t != 0 ? t : a.sortOrder.compareTo(b.sortOrder);
    });
    return [
      for (final c in pool)
        PickerItem(
          id: c.id,
          title: c.name,
          parentId: c.parentId,
          group: c.type.name,
          leading: IconDisplay(
            type: IconType.category,
            size: 32,
            iconCode: CategoryTree.resolveIconCode(c, all),
          ),
        ),
    ];
  }
}

class _Opened {
  const _Opened(this.result, this.lookup);

  final PickerResult result;
  final Category? Function(String? id) lookup;
}
