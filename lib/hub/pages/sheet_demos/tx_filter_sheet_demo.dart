import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../../ui/ui.dart';

/// Demo of [showTxFilterSideSheet] for the hub: buttons that open it with
/// sample data (English only).
Widget buildTxFilterSheetDemo(BuildContext context) =>
    const _TxFilterSheetDemo();

final _labels = TxFilterSheetLabels(
  title: 'Filters',
  apply: 'Apply',
  clear: 'Clear',
  all: 'All',
  more: 'More',
  typeTitle: 'Type',
  walletTitle: 'Wallet',
  categoryTitle: 'Category',
  tagTitle: 'Tag',
  amountTitle: 'Amount',
  amountMin: 'Min',
  amountMax: 'Max',
  expense: 'Expense',
  income: 'Income',
  transfer: 'Transfer',
  noWallet: 'No wallet',
  uncategorized: 'No category',
  noTag: 'No tag',
  walletPicker: const AccountPickerLabels(
    title: 'Wallet',
    none: 'No wallet',
    create: 'Add wallet',
    empty: 'No wallets',
  ),
  categoryPicker: CategoryMultiPickerLabels(
    title: 'Category',
    searchHint: 'Search',
    includeChildren: 'Include subcategories',
    confirm: (n) => 'OK ($n)',
    empty: 'No categories',
    noMatch: 'No match',
  ),
  tagPicker: const TagPickerLabels(
    title: 'Tag',
    searchHint: 'Search tags',
    ok: 'OK',
    addTag: 'Add tag',
    createNamed: _createNamed,
    empty: 'No tags',
    noMatch: 'No match',
    nameSave: 'Save',
    nameHint: 'Tag name',
  ),
  confirm: (n) => n == 0 ? 'OK' : 'OK ($n)',
);

String _createNamed(String name) => 'Add "$name"';

const _options = TxFilterOptions(
  wallets: [
    TxFilterOption(id: 'w1', label: 'Cash', icon: AppIcons.wallet),
    TxFilterOption(id: 'w2', label: 'Savings', icon: AppIcons.wallet),
    TxFilterOption(id: 'w3', label: 'Credit card', icon: AppIcons.wallet),
  ],
  categories: [
    TxFilterOption(
      id: 'c1',
      label: 'Food',
      icon: AppIcons.category,
      subtitle: 'Expense',
      sortOrder: 1,
      types: {TransactionType.expense},
    ),
    TxFilterOption(
      id: 'c2',
      label: 'Coffee',
      icon: AppIcons.category,
      parentId: 'c1',
      types: {TransactionType.expense},
    ),
    TxFilterOption(
      id: 'c3',
      label: 'Salary',
      icon: AppIcons.category,
      subtitle: 'Income',
      sortOrder: 2,
      types: {TransactionType.income},
    ),
  ],
  tags: [
    TxFilterOption(id: 't1', label: 'work', icon: AppIcons.tag),
    TxFilterOption(id: 't2', label: 'trip', icon: AppIcons.tag),
  ],
);

/// Far more chips than the 4 lines hold: "More" shows only here — in
/// [_options] every chip fits, so it is hidden.
final _manyOptions = TxFilterOptions(
  wallets: [
    for (var i = 1; i <= 24; i++)
      TxFilterOption(id: 'mw$i', label: 'Wallet $i', icon: AppIcons.wallet),
  ],
  categories: _options.categories,
  tags: [
    for (var i = 1; i <= 24; i++)
      TxFilterOption(id: 'mt$i', label: 'tag $i', icon: AppIcons.tag),
  ],
);

class _TxFilterSheetDemo extends StatefulWidget {
  const _TxFilterSheetDemo();

  @override
  State<_TxFilterSheetDemo> createState() => _TxFilterSheetDemoState();
}

class _TxFilterSheetDemoState extends State<_TxFilterSheetDemo> {
  String _result = 'nothing applied yet';

  Future<void> _open({
    required Future<TxFilterOptions> options,
    bool walletLocked = false,
    TxFilterSelection initial = const TxFilterSelection(),
  }) async {
    const empty = TxFilterSelection();
    final r = await showTxFilterSideSheet(
      context,
      initial: initial,
      reset: empty,
      options: options,
      labels: _labels,
      walletLocked: walletLocked,
    );
    if (!mounted) return;
    setState(
      () => _result = r == null
          ? 'dismissed'
          : 'types ${r.types.map((t) => t.name).toList()} '
                '| wallets ${r.walletIds}${r.noWallet ? ' + none' : ''} '
                '| categories ${r.categoryIds}${r.uncategorized ? ' + none' : ''} '
                '| tags ${r.tagIds}${r.noTags ? ' + none' : ''} '
                '| amount ${r.amountMin ?? '…'} – ${r.amountMax ?? '…'}',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            label: 'Filters',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(options: Future.value(_options)),
          ),
          AppButton(
            label: 'Loading (2 s)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(
              options: Future.delayed(
                const Duration(seconds: 2),
                () => _options,
              ),
            ),
          ),
          AppButton(
            label: 'Many options (More shows)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(options: Future.value(_manyOptions)),
          ),
          AppButton(
            label: 'Amount range preset',
            variant: AppButtonVariant.outlined,
            onPressed: () => _open(
              options: Future.value(_options),
              initial: const TxFilterSelection(amountMin: 100, amountMax: 5000),
            ),
          ),
          AppButton(
            label: 'Wallet locked',
            variant: AppButtonVariant.outlined,
            onPressed: () =>
                _open(options: Future.value(_options), walletLocked: true),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(_result),
    ],
  );
}
