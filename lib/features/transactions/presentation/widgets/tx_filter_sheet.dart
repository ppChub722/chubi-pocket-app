import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/category_label.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
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
    ),
    pickWallets: (context, current, _) async {
      final r = await AccountPicker.many(
        context,
        selected: current.ids.toSet(),
        allowNone: true,
        noneSelected: current.none,
        title: l.transactionsFilterAccount,
      );
      return r == null ? null : (ids: r.ids, none: r.none);
    },
    // The server takes a parent's sub-categories in too, so a ticked parent
    // always covers them.
    pickCategories: (context, current, types) async {
      final r = await CategoryPicker.many(
        context,
        types: _categoryTypes(types),
        initialType: types.length == 1 && types.single == TransactionType.income
            ? CategoryType.income
            : types.length == 1 && types.single == TransactionType.expense
            ? CategoryType.expense
            : null,
        selectedWithChildren: current.ids.toSet(),
        children: PickerChildren.always,
        allowNone: true,
        noneSelected: current.none,
        title: l.transactionsFilterCategory,
      );
      return r == null
          ? null
          : (ids: [for (final c in r.categories) c.id], none: r.none);
    },
    pickTags: (context, current, _) async {
      final r = await TagPicker.many(
        context,
        tags: loaded.tags,
        selected: current.ids.toSet(),
        allowCreate: false,
        allowNone: true,
        noneSelected: current.none,
        title: l.transactionsFilterTag,
      );
      return r == null ? null : (ids: r.ids.toList(), none: r.none);
    },
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

/// The category types the picker offers for the filter's transaction types
/// (none or transfer only = both).
Set<CategoryType> _categoryTypes(Set<TransactionType> types) {
  final out = {
    if (types.contains(TransactionType.expense)) CategoryType.expense,
    if (types.contains(TransactionType.income)) CategoryType.income,
  };
  return out.isEmpty ? const {CategoryType.expense, CategoryType.income} : out;
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
