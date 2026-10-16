import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

/// Demo of [showAccountPickSheet] for the hub: buttons that open it with
/// sample data (English only).
Widget buildAccountPickerSheetDemo(BuildContext context) =>
    const _AccountPickerSheetDemo();

const _labels = AccountPickerLabels(
  title: 'Choose a wallet',
  none: 'No wallet',
  create: 'Add wallet',
  empty: 'No wallets',
);

const _wallets = [
  WalletPickItem(
    id: 'w1',
    name: 'Cash',
    icon: PpForgeIcons.wallet,
    subtitle: 'Cash',
    balance: '฿1,250.50',
  ),
  WalletPickItem(
    id: 'w2',
    name: 'Savings',
    icon: PpForgeIcons.wallet,
    subtitle: 'Bank',
    balance: '฿48,200.00',
  ),
  WalletPickItem(
    id: 'w3',
    name: 'Credit card',
    icon: PpForgeIcons.wallet,
    subtitle: 'Credit card',
    balance: '-฿3,900.00',
  ),
];

class _AccountPickerSheetDemo extends StatefulWidget {
  const _AccountPickerSheetDemo();

  @override
  State<_AccountPickerSheetDemo> createState() =>
      _AccountPickerSheetDemoState();
}

class _AccountPickerSheetDemoState extends State<_AccountPickerSheetDemo> {
  String _result = 'nothing picked yet';

  Future<void> _open({
    List<WalletPickItem> wallets = _wallets,
    bool allowNone = false,
    bool allowCreate = false,
  }) async {
    final r = await showAccountPickSheet(
      context,
      wallets: wallets,
      labels: _labels,
      selectedId: 'w2',
      allowNone: allowNone,
      // The demo's "create flow" just makes a wallet id up.
      onCreate: allowCreate
          ? () => Future<String?>.delayed(
              const Duration(milliseconds: 300),
              () => 'new-wallet',
            )
          : null,
    );
    if (!mounted) return;
    setState(
      () => _result = switch (r) {
        null => 'dismissed',
        AccountPickWallet(:final id) => 'wallet $id',
        AccountPickNone() => 'no wallet',
      },
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
            label: 'Wallets',
            variant: PpForgeButtonVariant.outlined,
            onPressed: _open,
          ),
          PpForgeButton(
            label: 'With none + create',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () => _open(allowNone: true, allowCreate: true),
          ),
          PpForgeButton(
            label: 'Empty',
            variant: PpForgeButtonVariant.outlined,
            onPressed: () => _open(wallets: const []),
          ),
        ],
      ),
      const SizedBox(height: PpForgeSpacing.sm),
      Text(_result),
    ],
  );
}
