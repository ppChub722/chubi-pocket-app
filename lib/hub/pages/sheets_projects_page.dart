import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// `/dev/domain/sheets-projects` — the event sheets: resolve a board row into
/// my book, and invite a member. Sample data, live sheets.
Widget buildSheetsProjectsPage(BuildContext context) =>
    const _SheetsProjectsPage();

const _accounts = <ResolvePickValue>[
  ResolvePickValue(label: 'Cash', icon: AppIcons.wallet, color: Colors.green),
  ResolvePickValue(label: 'Savings', icon: AppIcons.bank, color: Colors.blue),
];

const _categories = <ResolvePickValue>[
  ResolvePickValue(label: 'Food', icon: AppIcons.category),
  ResolvePickValue(label: 'Travel', icon: AppIcons.category),
];

class _SheetsProjectsPage extends StatefulWidget {
  const _SheetsProjectsPage();

  @override
  State<_SheetsProjectsPage> createState() => _SheetsProjectsPageState();
}

class _SheetsProjectsPageState extends State<_SheetsProjectsPage> {
  String _result = 'nothing yet';

  EventResolveLabels get _labels => const EventResolveLabels(
    title: 'Record in my book',
    confirm: 'Record',
    amount: 'Amount',
    shareOnly: 'My share only',
    account: 'Account',
    accountEmpty: 'None',
    accountRequired: 'Pick an account',
    category: 'Category',
    categoryEmpty: 'No category',
    asTransaction: 'As transaction',
    asDebt: 'As debt',
    debtRow: 'Somchai owes you',
    debtHint: 'Recorded as a debt, no account needed.',
  );

  Future<ResolvePickResult?> _pick(List<ResolvePickValue> items) async {
    final r = await showOptionSheet<ResolvePickValue>(
      context,
      title: 'Pick',
      options: [for (final i in items) SheetOption(value: i, label: i.label)],
    );
    return r == null ? null : ResolvePickResult(r);
  }

  Future<void> _resolve({required bool parent}) async {
    final ok = await showEventResolveSheet(
      context,
      labels: _labels,
      amount: 1200,
      currencySymbol: '฿',
      shareAmount: parent ? 400 : null,
      shareHint: parent ? 'Row ฿1,200, children ฿800, my share ฿400' : null,
      showModeTabs: !parent,
      onPickAccount: (_) => _pick(_accounts),
      onPickCategory: (_) => _pick(_categories),
      onSubmit: (r) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return true;
      },
    );
    if (mounted) setState(() => _result = 'resolve: $ok');
  }

  Future<void> _addMember() async {
    final name = await showAddMemberFormSheet(
      context,
      labels: const AddMemberLabels(
        title: 'Invite member',
        submit: 'Add',
        fromContacts: 'From contacts',
        name: 'Name',
        nameRequired: 'Enter a name',
        email: 'Email',
        emailHint: 'Optional — with an email they get an invite.',
      ),
      onFromContacts: () async =>
          const AddMemberFill(name: 'Somchai', email: 'somchai@example.com'),
      onSubmit: (name, email) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return true;
      },
    );
    if (mounted) setState(() => _result = 'member: $name');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText('Last result: $_result'),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Resolve — split row (tabs)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _resolve(parent: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Resolve — parent row (share only)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _resolve(parent: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Add member',
            variant: AppButtonVariant.outlined,
            onPressed: _addMember,
          ),
        ],
      ),
    );
  }
}
