import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../data/personal_debts_repository.dart';
import '../../domain/personal_debt.dart';
import '../cubit/personal_debts_cubit.dart';

class PersonalDebtDetailPage extends StatefulWidget {
  const PersonalDebtDetailPage({required this.id, super.key});
  final String id;

  @override
  State<PersonalDebtDetailPage> createState() => _PersonalDebtDetailPageState();
}

class _PersonalDebtDetailPageState extends State<PersonalDebtDetailPage> {
  PersonalDebt? _debt;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d =
          await context.read<PersonalDebtsRepository>().get(widget.id);
      if (!mounted) return;
      setState(() {
        _debt = d;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_debt?.counterpartyPersonName ?? 'Debt')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _debt == null
                  ? const Center(child: Text('Not found'))
                  : _Body(debt: _debt!, onChanged: _load),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.debt, required this.onChanged});
  final PersonalDebt debt;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dirLabel = debt.isOwedToMe ? 'Owed to me' : 'I owe';
    final dirColor = debt.isOwedToMe ? Colors.green : Colors.redAccent;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(dirLabel),
                      backgroundColor: dirColor.withValues(alpha: 0.15),
                      side: BorderSide(color: dirColor),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(debt.status.wire),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Amount', style: theme.textTheme.labelSmall),
                Text('${debt.amount.toStringAsFixed(2)} ${debt.currency}',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Settled', style: theme.textTheme.labelSmall),
                Text(debt.settledAmount.toStringAsFixed(2)),
                const SizedBox(height: 12),
                Text('Outstanding', style: theme.textTheme.labelSmall),
                Text(
                  debt.outstanding.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium?.copyWith(color: dirColor),
                ),
                if (debt.note != null) ...[
                  const SizedBox(height: 12),
                  Text('Note', style: theme.textTheme.labelSmall),
                  Text(debt.note!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (debt.isOpen) ...[
          FilledButton.icon(
            icon: Icon(debt.isIOwe
                ? Icons.payments_outlined
                : Icons.call_received),
            label: Text(debt.isIOwe ? 'Pay' : 'Mark received'),
            onPressed: () => _settleDialog(context, direct: false),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('Settle without transaction'),
            onPressed: () => _settleDialog(context, direct: true),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel debt'),
            onPressed: () => _confirmCancel(context),
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          label: const Text('Delete',
              style: TextStyle(color: Colors.redAccent)),
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }

  Future<void> _settleDialog(BuildContext context, {required bool direct}) async {
    String? accountId;
    if (!direct) {
      final accountsCubit = context.read<AccountsCubit>();
      if (accountsCubit.state.accounts.isEmpty) {
        await accountsCubit.load();
      }
      if (!context.mounted) return;
      final accounts = accountsCubit.state.accounts;
      if (accounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No accounts available')),
        );
        return;
      }
      accountId = accounts.first.id;
    }

    final amountCtl =
        TextEditingController(text: debt.outstanding.toStringAsFixed(2));
    final accountCtlBag = _AccountBag(accountId);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(direct
            ? (debt.isIOwe ? 'Forgive / barter' : 'Mark received (no money)')
            : (debt.isIOwe ? 'Pay back' : 'Mark received')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!direct)
              _AccountPicker(
                bag: accountCtlBag,
                onChanged: (v) => accountCtlBag.id = v,
              ),
            TextField(
              controller: amountCtl,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            if (direct)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No transaction will be recorded — direct edit only.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final cubit = context.read<PersonalDebtsCubit>();
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    try {
      await cubit.settle(
        debt.id,
        accountId: direct ? null : accountCtlBag.id,
        amount: double.tryParse(amountCtl.text),
        direct: direct,
      );
      // The non-direct path created an income/expense transaction + moved
      // the account balance. The cubit only refreshed the debt; the
      // transactions list and account balances need explicit refresh
      // so the user sees the new row + updated balance when they
      // navigate to /transactions or back to the dashboard.
      if (!direct) {
        await Future.wait([
          txCubit.load(),
          accountsCubit.load(),
        ]);
      }
      if (!context.mounted) return;
      await onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel debt?'),
        content: const Text(
            'Marks status=cancelled. No money moves. Used for forgiveness or mistakes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel debt'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PersonalDebtsCubit>().cancel(debt.id);
      if (!context.mounted) return;
      await onChanged();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete debt?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PersonalDebtsCubit>().delete(debt.id);
      if (!context.mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _AccountBag {
  _AccountBag(this.id);
  String? id;
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.bag, required this.onChanged});
  final _AccountBag bag;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AccountsCubit>().state.accounts;
    return DropdownButtonFormField<String>(
      initialValue: bag.id,
      items: accounts
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Account'),
    );
  }
}
