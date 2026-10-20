import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/presentation/widgets/account_picker.dart';
import '../../categories/domain/category.dart';
import '../../categories/domain/category_tree.dart';
import '../../categories/domain/category_type.dart';
import '../../categories/presentation/widgets/category_picker.dart';
import '../../transactions/domain/refs.dart';
import '../domain/budget.dart';

/// A budget's categories: expense ones, each parent with its own "include
/// sub-categories" box.
Future<List<BudgetScopeCategory>?> showBudgetCategoriesPicker(
  BuildContext context, {
  required List<Category> all,
  required List<BudgetScopeCategory> selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final r = await CategoryPicker.many(
    context,
    types: const {CategoryType.expense},
    children: PickerChildren.toggle,
    title: l.multiPickCategoriesTitle,
    selected: {
      for (final s in selected)
        if (!s.includeChildren) s.category.id,
    },
    selectedWithChildren: {
      for (final s in selected)
        if (s.includeChildren) s.category.id,
    },
  );
  if (r == null) return null;
  final picked = {for (final c in r.categories) c.id: c};
  final before = {for (final s in selected) s.category.id: s.category};
  return [
    for (final id in r.ids)
      // A ticked category the cache no longer has keeps what it had.
      if (picked[id] case final c?)
        BudgetScopeCategory(
          category: EmbeddedCategory(
            id: c.id,
            name: c.name,
            type: c.type,
            iconCode: CategoryTree.resolveIconCode(c, all),
            parentId: c.parentId,
          ),
          includeChildren: r.withChildren.contains(id),
        )
      else if (before[id] case final e?)
        BudgetScopeCategory(
          category: e,
          includeChildren: r.withChildren.contains(id),
        ),
  ];
}

/// A budget's wallets: the ticked ids, also one no longer in the cache (the
/// caller keeps what it had for it).
Future<List<String>?> showBudgetWalletsPicker(
  BuildContext context, {
  required List<String> selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final r = await AccountPicker.many(
    context,
    selected: selected.toSet(),
    title: l.multiPickWalletsTitle,
  );
  return r?.ids;
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
