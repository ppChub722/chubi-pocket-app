import 'package:flutter/material.dart';

import '../../../features/transactions/domain/transaction_type.dart';
import '../../../ui/ui.dart';

/// Demo of [showTxFilterSideSheet] for the hub: buttons that open it with
/// sample data (English only).
Widget buildTxFilterSheetDemo(BuildContext context) =>
    const _TxFilterSheetDemo();

const _labels = TxFilterSheetLabels(
  title: 'Filters',
  apply: 'Apply',
  clear: 'Clear',
  all: 'All',
  more: 'More',
  typeTitle: 'Type',
  walletTitle: 'Wallet',
  categoryTitle: 'Category',
  tagTitle: 'Tag',
  expense: 'Expense',
  income: 'Income',
  transfer: 'Transfer',
  noWallet: 'No wallet',
  uncategorized: 'Uncategorized',
);

const _options = TxFilterOptions(
  wallets: [
    TxFilterOption(id: 'w1', label: 'Cash', icon: PpForgeIcons.wallet),
    TxFilterOption(id: 'w2', label: 'Savings', icon: PpForgeIcons.wallet),
    TxFilterOption(id: 'w3', label: 'Credit card', icon: PpForgeIcons.wallet),
  ],
  categories: [
    TxFilterOption(
      id: 'c1',
      label: 'Food',
      icon: PpForgeIcons.category,
      subtitle: 'Expense',
      sortOrder: 1,
      types: {TransactionType.expense},
    ),
    TxFilterOption(
      id: 'c2',
      label: 'Coffee',
      icon: PpForgeIcons.category,
      parentId: 'c1',
      types: {TransactionType.expense},
    ),
    TxFilterOption(
      id: 'c3',
      label: 'Salary',
      icon: PpForgeIcons.category,
      subtitle: 'Income',
      sortOrder: 2,
      types: {TransactionType.income},
    ),
  ],
  tags: [
    TxFilterOption(id: 't1', label: 'work', icon: PpForgeIcons.tag),
    TxFilterOption(id: 't2', label: 'trip', icon: PpForgeIcons.tag),
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
  }) async {
    const empty = TxFilterSelection();
    final r = await showTxFilterSideSheet(
      context,
      initial: empty,
      reset: empty,
      options: options,
      labels: _labels,
      walletLocked: walletLocked,
    );
    if (!mounted) return;
    setState(
      () => _result = r == null
          ? 'dismissed'
          : 'type ${r.type?.name} · wallet ${r.noWallet ? 'none' : r.walletId} '
                '· category ${r.uncategorized ? 'none' : r.categoryId} '
                '· tags ${r.tagIds}',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: PpForgeSpacing.sm,
        runSpacing: PpForgeSpacing.sm,
        children: [
          PpForgeButton(
            label: 'Filters',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () => _open(options: Future.value(_options)),
          ),
          PpForgeButton(
            label: 'Loading (2 s)',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () => _open(
              options: Future.delayed(
                const Duration(seconds: 2),
                () => _options,
              ),
            ),
          ),
          PpForgeButton(
            label: 'Wallet locked',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () =>
                _open(options: Future.value(_options), walletLocked: true),
          ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.sm),
      Text(_result),
    ],
  );
}
