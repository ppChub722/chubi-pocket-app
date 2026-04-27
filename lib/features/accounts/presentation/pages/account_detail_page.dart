import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';

/// Account detail — Phase 0 mock implementation.
///
/// Routed at `/accounts/:id` outside the shell, so it owns its own Scaffold
/// + AppBar with a back button. The bottom nav and the global Add-transaction
/// FAB do NOT show here.
///
/// What's real now: header (icon + name + balance + type), credit-only
/// utilization bar + available-credit row, billing card, summary card with
/// zero values, transactions empty-state, overflow menu (Edit / Adjust
/// balance / Archive). Edit / Adjust / Archive each show "Coming in Phase
/// 1a" snackbars — the underlying flows ship with the real backend in P1a.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, List<Account>>(
      builder: (context, _) {
        final account = context.read<AccountsCubit>().byId(accountId);
        if (account == null) return _NotFoundScaffold();
        return _LoadedScaffold(account: account);
      },
    );
  }
}

class _NotFoundScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.find_in_page_outlined,
        title: l.accountDetailNotFound,
        message: l.accountDetailNotFoundMessage,
      ),
    );
  }
}

class _LoadedScaffold extends StatelessWidget {
  const _LoadedScaffold({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          PopupMenuButton<_OverflowAction>(
            onSelected: (_) => _showComingSoon(context, l),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _OverflowAction.edit,
                child: Row(children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.accountDetailEdit),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.adjustBalance,
                child: Row(children: [
                  const Icon(Icons.tune_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.accountDetailAdjustBalance),
                ]),
              ),
              PopupMenuItem(
                value: _OverflowAction.archive,
                child: Row(children: [
                  const Icon(Icons.archive_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.accountDetailArchive),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        children: [
          _Header(account: account),
          if (account.note != null && account.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(note: account.note!),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SummaryCard(account: account),
          if (account.type.isCredit) ...[
            const SizedBox(height: AppSpacing.lg),
            _BillingCard(account: account),
          ],
          const SizedBox(height: AppSpacing.lg),
          _TransactionsSection(),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.accountDetailActionComingSoon)),
      );
  }
}

enum _OverflowAction { edit, adjustBalance, archive }

class _Header extends StatelessWidget {
  const _Header({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: account.color.color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: account.color.color,
                shape: BoxShape.circle,
              ),
              child: Icon(account.icon.icon,
                  size: 30, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              CurrencyFormatter.format(account.balance),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: account.color.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${account.currency} · ${_typeLabel(context, account.type)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (account.creditUtilization != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: account.creditUtilization,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(account.color.color),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.accountDetailCreditAvailable(
                  CurrencyFormatter.format(
                    (account.creditLimit ?? 0) - account.balance.abs(),
                  ),
                  CurrencyFormatter.format(account.creditLimit ?? 0),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                note,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.accountDetailSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: l.accountDetailSummaryIncome,
                    amount: 0,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: l.accountDetailSummaryExpense,
                    amount: 0,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: l.accountDetailSummaryNet,
                    amount: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.accountDetailSummaryTransactions(0),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.accountDetailBillingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (account.statementDate != null)
              _BillingRow(
                icon: Icons.event_note_outlined,
                label: l.accountDetailStatementDate,
                value:
                    l.accountDetailDayOfMonth(account.statementDate!),
              ),
            if (account.paymentDueDate != null)
              _BillingRow(
                icon: Icons.event_available_outlined,
                label: l.accountDetailPaymentDue,
                value:
                    l.accountDetailDayOfMonth(account.paymentDueDate!),
              ),
            if (account.minimumPayment != null)
              _BillingRow(
                icon: Icons.payments_outlined,
                label: l.accountDetailMinimumPayment,
                value: CurrencyFormatter.format(account.minimumPayment!),
              ),
          ],
        ),
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  const _BillingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.accountDetailTransactionsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: l.accountDetailTransactionsEmptyTitle,
              message: l.accountDetailTransactionsEmptyMessage,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(BuildContext context, AccountType type) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case AccountType.cash:
      return l.accountTypeCash;
    case AccountType.bank:
      return l.accountTypeBank;
    case AccountType.eWallet:
      return l.accountTypeEWallet;
    case AccountType.creditCard:
      return l.accountTypeCreditCard;
    case AccountType.payLater:
      return l.accountTypePayLater;
  }
}
