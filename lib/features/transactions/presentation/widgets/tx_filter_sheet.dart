import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../cubit/tx_form_options_cubit.dart';
import '../../domain/form_options.dart';
import '../../domain/transaction_type.dart';
import '../tx_list_filters.dart';

Future<TxFilters?> showTxFilterSheet(
  BuildContext context, {
  required TxFilters current,
  required TxFilters base,
  bool walletLocked = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final palette = Theme.of(context).extension<AppColors>()!;
  var loaded = const TxFormOptions();
  Future<TxFilterOptions> load() async {
    final cubit = context.read<TxFormOptionsCubit>();
    try {
      await cubit.loadIfNeeded();
    } catch (_) {}
    loaded = cubit.state.options ?? loaded;
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
      amountTitle: l.txFilterAmount,
      amountMin: l.txFilterAmountMin,
      amountMax: l.txFilterAmountMax,
      expense: l.transactionTypeExpense,
      income: l.transactionTypeIncome,
      transfer: l.transactionTypeTransfer,
      noWallet: l.txFilterNoWallet,
      uncategorized: l.txFilterNoCategory,
      noTag: l.txFilterNoTag,
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
    amount: (min: picked.amountMin, max: picked.amountMax),
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
  amountMin: f.amountMin,
  amountMax: f.amountMax,
);

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
