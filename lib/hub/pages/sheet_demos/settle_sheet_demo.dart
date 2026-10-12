import 'package:flutter/material.dart';

import '../../../features/accounts/domain/account.dart';
import '../../../features/accounts/domain/account_type.dart';
import '../../../features/accounts/presentation/widgets/wallet_pick_card.dart';
import '../../../ui/ui.dart';

/// Demo of [showSettleSheet] for the hub: buttons that open it with sample
/// data (English only). Tapping the wallet card cycles the sample wallets.
Widget buildSettleSheetDemo(BuildContext context) => const _SettleSheetDemo();

const _wallets = [
  Account(
    id: 'a1',
    name: 'Savings',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
  ),
  Account(
    id: 'a2',
    name: 'Cash',
    type: AccountType.cash,
    balance: 1250.5,
    currency: 'THB',
  ),
];

String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

class _SettleSheetDemo extends StatefulWidget {
  const _SettleSheetDemo();

  @override
  State<_SettleSheetDemo> createState() => _SettleSheetDemoState();
}

class _SettleSheetDemoState extends State<_SettleSheetDemo> {
  String _result = 'nothing settled yet';

  Future<void> _open({
    required bool receive,
    required double outstanding,
    double? initial,
    String? description,
    bool fail = false,
  }) async {
    final r = await showSettleSheet(
      context,
      data: SettleSheetData(
        isReceive: receive,
        outstanding: outstanding,
        symbol: '฿',
        description: description,
        initialAmount: initial,
      ),
      labels: SettleSheetLabels(
        title: receive ? 'Receive from Aom' : 'Pay back Aom',
        confirm: 'Settle',
        amountLabel: 'Outstanding',
        amountRequired: 'Enter an amount',
        amountOver: (o) => 'More than the outstanding $o',
        all: 'All',
        half: 'Half',
        noteLabel: 'Note',
        descriptionHint: 'What for?',
        formatDate: _formatDate,
      ),
      initialAccount: _wallets.first,
      walletField: (ctx, selected, onChanged) => WalletPickCard(
        account: selected,
        label: 'Wallet',
        placeholder: 'No wallet',
        onTap: () => onChanged(
          selected == _wallets.first ? _wallets.last : _wallets.first,
        ),
      ),
      onConfirm: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return fail ? 'The server said no (demo failure)' : null;
      },
    );
    if (r != null && mounted) {
      setState(
        () => _result =
            '${r.amount} on ${_formatDate(r.date)}, wallet ${r.account?.name}, '
            'description ${r.description}, note ${r.note}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: 'Receive',
              variant: AppButtonVariant.outlined,
              onPressed: () => _open(
                receive: true,
                outstanding: 1200,
                description: 'Lunch money',
              ),
            ),
            AppButton(
              label: 'Pay back (pre-filled 300)',
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  _open(receive: false, outstanding: 800, initial: 300),
            ),
            AppButton(
              label: 'Overpaid (cannot settle)',
              variant: AppButtonVariant.outlined,
              onPressed: () => _open(receive: true, outstanding: -50),
            ),
            AppButton(
              label: 'Failing call',
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  _open(receive: true, outstanding: 500, fail: true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppText('Result: $_result'),
      ],
    );
  }
}
