import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../data/transactions_repository.dart';
import '../../domain/form_options.dart';
import '../../domain/transaction_type.dart';
import '../tx_list_filters.dart';

/// The transactions list's filters, in a side sheet from the right (owner
/// 2026-10-10) — the thin wrapper of the kit's [TxFilterSheet]: it loads the
/// form's options (one call, as the sheet opens), maps them and [TxFilters]
/// to the organism's plain data + l10n words, and maps the result back. The
/// period and the sort live on the page (its pill and ⇅) — the sheet carries
/// them through untouched.
///
/// Resolves the new filters, or null when closed without applying. ล้าง
/// goes back to [base] (how the list opened — a wallet's list keeps its
/// wallet) but keeps the page's period and sort; [walletLocked] hides the
/// wallet section (a wallet's own list).
Future<TxFilters?> showTxFilterSheet(
  BuildContext context, {
  required TxFilters current,
  required TxFilters base,
  required TransactionsRepository repository,
  bool walletLocked = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  // What the sheet's load found — to map the picked ids back to models.
  var loaded = const TxFormOptions();
  Future<TxFilterOptions> load() async {
    try {
      loaded = await repository.formOptions();
    } catch (_) {
      // The rows stay empty; the type chips and apply still work.
    }
    return _filterOptions(l, palette, loaded);
  }

  final picked = await showTxFilterSideSheet(
    context,
    initial: _selectionOf(current),
    reset: _selectionOf(base),
    options: load(),
    walletLocked: walletLocked,
    labels: TxFilterSheetLabels(
      title: l.transactionsFiltersTitle,
      apply: l.transactionsFiltersApply,
      clear: l.commonClear,
      all: l.transactionsListFilterAll,
      more: l.commonMore,
      typeTitle: l.transactionsFilterType,
      walletTitle: l.transactionsFilterAccount,
      categoryTitle: l.transactionsFilterCategory,
      tagTitle: l.transactionsFilterTag,
      expense: l.transactionTypeExpense,
      income: l.transactionTypeIncome,
      transfer: l.transactionTypeTransfer,
      noWallet: l.txFilterNoWallet,
      uncategorized: l.txFilterNoCategory,
      noTag: l.txFilterNoTag,
      // The pickers behind "more": the same ones the create form opens, here
      // with several picks.
      walletPicker: AccountPickerLabels(
        title: l.transactionsFilterAccount,
        none: l.txFilterNoWallet,
        create: l.accountsAddNew,
        empty: l.transactionFormAccountPickerEmpty,
      ),
      categoryPicker: CategoryMultiPickerLabels(
        title: l.transactionsFilterCategory,
        searchHint: l.multiPickSearch,
        includeChildren: l.multiPickIncludeChildren,
        confirm: l.multiPickConfirm,
        empty: l.multiPickEmpty,
        noMatch: l.multiPickNoMatch,
      ),
      tagPicker: TagPickerLabels(
        title: l.transactionsFilterTag,
        searchHint: l.tagPickerSearchHint,
        ok: l.commonOk,
        addTag: l.projectTxAddTag,
        createNamed: l.tagPickerCreateNamed,
        empty: l.tagPickerEmpty,
        noMatch: l.tagPickerNoMatch,
        nameSave: l.commonSave,
        nameHint: l.projectTxTagHint,
      ),
      confirm: (n) => n == 0 ? l.commonOk : '${l.commonOk} ($n)',
    ),
  );
  if (picked == null) return null;
  // The picked ids back to models: what the page already holds, then what
  // the sheet's load found (a drill-down opens with just an id and a name).
  final categories = {
    for (final c in current.categories) c.id: c,
    for (final c in loaded.categoryList) c.id: c,
  };
  final accounts = {
    for (final a in current.wallets) a.id: a,
    for (final a in loaded.accountList) a.id: a,
  };
  final tags = {
    for (final t in current.tags) t.id: t,
    for (final t in loaded.tags) t.id: t,
  };
  return current.copyWith(
    types: picked.types,
    wallets: [
      for (final id in picked.walletIds)
        if (accounts[id] != null) accounts[id]!,
    ],
    noWallet: picked.noWallet,
    categories: [
      for (final id in picked.categoryIds)
        if (categories[id] != null) categories[id]!,
    ],
    uncategorized: picked.uncategorized,
    tags: [
      for (final id in picked.tagIds)
        if (tags[id] != null) tags[id]!,
    ],
    noTags: picked.noTags,
  );
}

TxFilterSelection _selectionOf(TxFilters f) => TxFilterSelection(
  types: f.types,
  walletIds: [for (final a in f.wallets) a.id],
  noWallet: f.noWallet,
  categoryIds: [for (final c in f.categories) c.id],
  uncategorized: f.uncategorized,
  tagIds: [for (final t in f.tags) t.id],
  noTags: f.noTags,
);

/// The form options as the organism's pick rows: active non-system
/// categories in display order, tags by usage.
TxFilterOptions _filterOptions(
  AppLocalizations l,
  AppColors palette,
  TxFormOptions o,
) => TxFilterOptions(
  wallets: [
    for (final a in o.accountList)
      TxFilterOption(
        id: a.id,
        label: a.name,
        icon: IconRegistry.get(a.iconCode?.icon, fallback: a.type.icon),
        color: a.iconCode.tintFor(palette),
        listIcon: a.type.icon,
        iconCode: a.iconCode,
      ),
  ],
  categories: [
    for (final c in o.categoryList)
      if (!c.isSystem)
        TxFilterOption(
          id: c.id,
          label: categoryDisplayName(l, c),
          // The category's own icon (sub-categories too).
          icon: IconRegistry.get(c.iconCode?.icon, fallback: AppIcons.category),
          color: c.iconCode.tintFor(palette),
          subtitle: c.type == CategoryType.income
              ? l.transactionTypeIncome
              : l.transactionTypeExpense,
          parentId: c.parentId,
          sortOrder: c.sortOrder,
          iconCode: c.iconCode,
          types: {
            if (c.type == CategoryType.income)
              TransactionType.income
            else
              TransactionType.expense,
          },
        ),
  ],
  tags: [
    for (final t in [
      ...o.tags,
    ]..sort((a, b) => b.usageCount.compareTo(a.usageCount)))
      TxFilterOption(
        id: t.id,
        label: t.name.isEmpty ? l.tagFormNameLabel : t.name,
        icon: IconRegistry.get(t.iconCode?.icon, fallback: AppIcons.tag),
        color: tagColor(t.iconCode, palette),
        iconCode: t.iconCode,
      ),
  ],
);

/// Labels the list and the sheet share.
String txTypeLabel(AppLocalizations l, TransactionType? t) => switch (t) {
  null => l.transactionsListFilterAll,
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};

String txSortLabel(AppLocalizations l, String sort) => switch (sort) {
  'date_asc' => l.transactionsSortOldest,
  'amount_desc' => l.transactionsSortAmountHigh,
  'amount_asc' => l.transactionsSortAmountLow,
  _ => l.transactionsSortNewest,
};
