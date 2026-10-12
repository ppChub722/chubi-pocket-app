import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/domain/sheets-accounts` — the wallet sheets as presentational
/// organisms (sample data, no cubit / repository): adjust balance, bank
/// picker, identifier kind picker, wallet invite picker.
Widget buildSheetsAccountsPage(BuildContext context) =>
    const _SheetsAccountsPage();

const _banks = [
  BankPickerItem(
    code: '004',
    name: 'Kasikornbank',
    nameEn: 'Kasikornbank',
    shortName: 'KBANK',
  ),
  BankPickerItem(
    code: '014',
    name: 'Siam Commercial Bank',
    nameEn: 'Siam Commercial Bank',
    shortName: 'SCB',
  ),
  BankPickerItem(
    code: '025',
    name: 'Bank of Ayudhya',
    nameEn: 'Bank of Ayudhya',
    shortName: 'BAY',
  ),
  BankPickerItem(code: '999', name: 'Sample Bank', nameEn: 'Sample Bank'),
];

const _kinds = [
  IdentifierKindOption(
    id: 'account',
    label: 'Bank account',
    icon: AppIcons.bank,
    hasBank: true,
  ),
  IdentifierKindOption(
    id: 'promptpay',
    label: 'PromptPay',
    icon: AppIcons.eWallet,
  ),
  IdentifierKindOption(
    id: 'card',
    label: 'Card',
    icon: AppIcons.creditCard,
    hasBank: true,
  ),
  IdentifierKindOption(
    id: 'other',
    label: 'Other',
    icon: AppIcons.accountNumber,
  ),
];

const _candidates = [
  WalletInviteCandidate(id: '1', name: 'Aom Chan', email: 'aom@example.com'),
  WalletInviteCandidate(id: '2', name: 'Bee', email: 'bee@example.com'),
  WalletInviteCandidate(id: '3', name: 'Cat'),
];

AdjustBalanceStrings _adjustStrings({required bool credit}) =>
    AdjustBalanceStrings(
      title: 'Adjust balance',
      primaryLabel: 'Adjust',
      currentLabel: 'Current balance',
      newLabel: credit ? 'New debt' : 'New balance',
      diffLabel: 'Difference',
      descriptionLabel: 'Description',
      noteLabel: 'Note',
      noChange: 'No change.',
      willCreate: (diff) => 'Creates an adjustment of $diff, dated today.',
    );

class _SheetsAccountsPage extends StatefulWidget {
  const _SheetsAccountsPage();

  @override
  State<_SheetsAccountsPage> createState() => _SheetsAccountsPageState();
}

class _SheetsAccountsPageState extends State<_SheetsAccountsPage> {
  String _result = 'nothing picked yet';
  void _say(Object? v) => setState(() => _result = '$v');

  Widget _open(String label, Future<void> Function() open) => AppButton(
    label: label,
    onPressed: open,
    variant: AppButtonVariant.outlined,
  );

  Future<void> _adjust({required bool credit, required double balance}) async {
    final r = await showAdjustBalanceFormSheet(
      context,
      name: credit ? 'Credit card' : 'Savings',
      balance: balance,
      symbol: '฿',
      isCredit: credit,
      strings: _adjustStrings(credit: credit),
    );
    _say(
      r == null
          ? 'dismissed'
          : 'balance ${r.balance} · description ${r.description} · note ${r.note}',
    );
  }

  Future<void> _bank({required bool allowNone, String? selected}) async {
    final r = await showBankSelectSheet(
      context,
      banks: _banks,
      allowNone: allowNone,
      selectedCode: selected,
      strings: const BankPickerStrings(
        title: 'Bank',
        noneLabel: 'Not specified',
      ),
    );
    _say(r == null ? 'dismissed' : 'bank ${r.code ?? 'none'}');
  }

  Future<void> _kind(String kindId, String? bankCode) async {
    final r = await showIdentifierKindSelectSheet(
      context,
      kinds: _kinds,
      currentKindId: kindId,
      currentBankCode: bankCode,
      banks: _banks,
      strings: const IdentifierKindStrings(
        title: 'Kind',
        bankLabel: 'Bank',
        bankNoneLabel: 'Not specified',
      ),
    );
    _say(r == null ? 'dismissed' : 'kind ${r.kindId} · bank ${r.bankCode}');
  }

  Future<void> _invite(List<WalletInviteCandidate> list) async {
    final r = await showWalletInviteSelectSheet(
      context,
      candidates: list,
      strings: const WalletInviteStrings(
        title: 'Invite to this wallet',
        searchHint: 'Search contacts',
        hint: 'Only contacts linked to an app account can be invited.',
        empty: 'Nobody to invite: link a contact to an app account first.',
      ),
    );
    _say(r == null ? 'dismissed' : 'invite ${r.name}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          columns: 2,
          note:
              'The wallet sheets are presentational organisms; the accounts '
              'feature wraps each with its models + strings. These open the '
              'same sheets from sample data.',
          uses: [
            HubUse(
              label: 'Adjust balance — savings',
              page: 'Wallet detail',
              child: _open(
                'Open',
                () => _adjust(credit: false, balance: 48200),
              ),
            ),
            HubUse(
              label: 'Adjust balance — credit (debt) / negative',
              page: 'Wallet detail',
              child: _open(
                'Open',
                () => _adjust(credit: true, balance: -12400),
              ),
            ),
            HubUse(
              label: 'Bank picker — with "none"',
              page: 'Wallet numbers, wallet edit',
              child: _open(
                'Open',
                () => _bank(allowNone: true, selected: '014'),
              ),
            ),
            HubUse(
              label: 'Bank picker — without "none"',
              page: 'Wallet edit',
              child: _open('Open', () => _bank(allowNone: false)),
            ),
            HubUse(
              label: 'Identifier kind — bank account + bank',
              page: 'Wallet numbers (edit row chip)',
              child: _open('Open', () => _kind('account', '004')),
            ),
            HubUse(
              label: 'Identifier kind — PromptPay',
              page: 'Wallet numbers (edit row chip)',
              child: _open('Open', () => _kind('promptpay', null)),
            ),
            HubUse(
              label: 'Wallet invite — contacts',
              page: 'Wallet members',
              child: _open('Open', () => _invite(_candidates)),
            ),
            HubUse(
              label: 'Wallet invite — nobody to invite',
              page: 'Wallet members',
              child: _open('Open', () => _invite(const [])),
            ),
          ],
        ),
        HubDemo(
          title: 'Last result',
          child: Text(
            _result,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const HubDemo(
          title: 'Bank mark',
          note:
              'BankBrandMark — brand colour by BOT code, lettered from the '
              'short name.',
          child: Wrap(
            spacing: AppSpacing.md,
            children: [
              BankBrandMark(code: '004', shortName: 'KBANK'),
              BankBrandMark(code: '014', shortName: 'SCB', size: 24),
              BankBrandMark(code: '999', nameEn: 'Sample Bank'),
            ],
          ),
        ),
      ],
    );
  }
}
