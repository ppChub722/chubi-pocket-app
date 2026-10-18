import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/cubit_feed.dart';
import '../../../core/data/sync_refresh.dart';
import '../../../core/data/sync_set.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../categories/presentation/cubit/categories_cubit.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_tree.dart';
import '../../categories/domain/category_type.dart';
import '../../transactions/domain/refs.dart';
import '../domain/budget.dart';

Future<List<BudgetScopeCategory>?> showBudgetCategoriesPicker(
  BuildContext context, {
  required List<Category> all,
  required List<BudgetScopeCategory> selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final pool = [
    for (final c in all)
      if (!c.isSystem && c.type == CategoryType.expense) c,
  ];
  List<CategoryPickerRow> rowsOf(List<Category> source) => [
    for (final c in source)
      if (!c.isSystem && c.type == CategoryType.expense)
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
  final feed = cache == null
      ? null
      : CubitFeed<CategoriesState, List<CategoryPickerRow>>(
          cache,
          (s) => rowsOf(s.categories),
        );
  final picks = await showCategoryMultiPicker(
    context,
    rows: rowsOf(all),
    live: feed?.listenable,
    onRefresh: cache == null
        ? null
        : syncRefreshOf(context, const {SyncSet.categories}),
    labels: CategoryMultiPickerLabels(
      title: l.multiPickCategoriesTitle,
      searchHint: l.multiPickSearch,
      includeChildren: l.multiPickIncludeChildren,
      confirm: l.multiPickConfirm,
      empty: l.multiPickEmpty,
      noMatch: l.multiPickNoMatch,
    ),
    initial: [
      for (final s in selected)
        (id: s.category.id, includeChildren: s.includeChildren),
    ],
  );
  await feed?.dispose();
  if (picks == null) return null;
  final byId = {for (final c in pool) c.id: c};
  final known = {for (final s in selected) s.category.id: s.category};
  return [
    for (final p in picks)
      if (byId[p.id] ?? known[p.id]?.toCategory() case final c?)
        BudgetScopeCategory(
          category: EmbeddedCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            iconCode: CategoryTree.resolveIconCode(c, all),
            parentId: c.parentId,
          ),
          includeChildren: p.includeChildren,
        ),
  ];
}

Future<List<String>?> showBudgetWalletsPicker(
  BuildContext context, {
  required List<Account> all,
  required List<String> selected,
}) async {
  final l = AppLocalizations.of(context)!;
  List<AccountMultiPickItem> itemsOf(List<Account> source) => [
    for (final a in source)
      if (!a.isArchived || selected.contains(a.id))
        AccountMultiPickItem(
          id: a.id,
          name: a.name,
          icon: IconRegistry.get(a.iconCode?.icon, fallback: AppIcons.wallet),
          balance: a.showsBalance ? moneyString(context, a.balance) : null,
        ),
  ];
  AccountsCubit? cache;
  try {
    cache = context.read<AccountsCubit>();
  } catch (_) {
    cache = null; // no cache here (a test, the hub): the list as given
  }
  final feed = cache == null
      ? null
      : CubitFeed<AccountsState, List<AccountMultiPickItem>>(
          cache,
          (s) => itemsOf(s.allAccounts),
        );
  final picked = await showAccountMultiPicker(
    context,
    wallets: itemsOf(all),
    live: feed?.listenable,
    onRefresh: cache == null
        ? null
        : syncRefreshOf(context, const {SyncSet.accounts}),
    labels: AccountMultiPickerLabels(
      title: l.multiPickWalletsTitle,
      searchHint: l.multiPickSearch,
      confirm: l.multiPickConfirm,
      empty: l.multiPickEmpty,
      noMatch: l.multiPickNoMatch,
    ),
    initial: selected,
  );
  await feed?.dispose();
  return picked;
}

List<AccountRef> budgetWalletRefs(
  List<Account> all,
  List<String> ids,
  List<AccountRef> existing,
) {
  final out = <AccountRef>[];
  for (final id in ids) {
    final a = all.where((x) => x.id == id).firstOrNull;
    if (a != null) {
      out.add(
        AccountRef(
          id: a.id,
          name: a.name,
          iconCode: a.iconCode,
          type: a.type,
          group: a.isLiability ? 'liability' : 'asset',
          currency: a.currency,
          archived: a.isArchived,
        ),
      );
    } else if (existing.where((x) => x.id == id).firstOrNull case final e?) {
      out.add(e);
    }
  }
  return out;
}
