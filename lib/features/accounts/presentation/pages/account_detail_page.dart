import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/domain/transactions_summary.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
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
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        // While the cold-start fetch is in flight and the cache is empty,
        // show a spinner instead of the "not found" empty-state — the user
        // navigated here from a list, so the account *should* exist.
        if (state.accounts.isEmpty &&
            state.status == AccountsStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
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
            onSelected: (action) => _onMenuAction(context, l, action),
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
          if (account.description != null &&
              account.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _MetaCard(
              icon: Icons.info_outline,
              text: account.description!,
            ),
          ],
          if (account.note != null && account.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _MetaCard(
              icon: Icons.sticky_note_2_outlined,
              text: account.note!,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _LiveSummaryCard(accountId: account.id),
          if (account.type.isCredit) ...[
            const SizedBox(height: AppSpacing.lg),
            _BillingCard(account: account),
          ],
          const SizedBox(height: AppSpacing.lg),
          _LiveTransactionsSection(accountId: account.id),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    AppLocalizations l,
    _OverflowAction action,
  ) async {
    switch (action) {
      case _OverflowAction.edit:
        context.push('/accounts/${account.id}/edit');
      case _OverflowAction.adjustBalance:
        await _showAdjustBalanceDialog(context, l);
      case _OverflowAction.archive:
        await _confirmArchive(context, l);
    }
  }

  Future<void> _showAdjustBalanceDialog(
      BuildContext context, AppLocalizations l) async {
    final result = await showDialog<_AdjustBalanceResult>(
      context: context,
      builder: (_) => _AdjustBalanceDialog(account: account),
    );
    if (result == null || !context.mounted) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final outcome = await cubit.adjustBalance(
        id: account.id,
        newBalance: result.newBalance,
        note: result.note,
      );
      // Refresh the account-detail's transactions section so the new
      // Adjustment row shows up immediately. The cubit already patched
      // the account row's balance via the response.
      if (context.mounted) {
        await context
            .read<TransactionsCubit>()
            .load(accountId: account.id);
      }
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.accountAdjustBalanceSuccess),
          action: SnackBarAction(
            label: l.accountAdjustBalanceViewTransaction,
            onPressed: () => router.push(
              '/transactions/${outcome.adjustmentTransactionId}',
            ),
          ),
        ));
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmArchive(
      BuildContext context, AppLocalizations l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountArchiveConfirmTitle),
        content: Text(l.accountArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.accountArchiveConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final cubit = context.read<AccountsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await cubit.remove(account.id);
      // Pop back to the list — the account is no longer in the active
      // cache, so the detail page would otherwise flip into "not found".
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
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
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        account.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tap the icon to jump straight to the edit form (where the
            // IconMaker picker is wired). Same destination as the overflow
            // menu's "Edit" item.
            InkWell(
              onTap: () => context.push('/accounts/${account.id}/edit'),
              borderRadius: BorderRadius.circular(28),
              child: IconDisplay(
                type: IconType.account,
                size: 56,
                iconCode: account.iconCode,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              CurrencyFormatter.format(account.balance),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: accent,
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
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
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

/// Renders a small text card with a leading icon. Used for both the
/// description (info icon) and note (sticky-note icon) blocks above the
/// summary card. Each only appears when the underlying string is set.
class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
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

/// Range chips drive the per-account summary.
enum _SummaryRange { week, month, year, all }

extension on _SummaryRange {
  /// Returns `(from, to)` as `YYYY-MM-DD` strings, or `(null, null)` for
  /// `all` (which sends no date params; the BE summarizes everything).
  ({String? from, String? to}) toRange(DateTime now) {
    String fmt(DateTime d) {
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    }
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _SummaryRange.week:
        // Mon..Sun. weekday: Mon=1..Sun=7.
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (from: fmt(monday), to: fmt(sunday));
      case _SummaryRange.month:
        final first = DateTime(now.year, now.month, 1);
        final last = DateTime(now.year, now.month + 1, 0);
        return (from: fmt(first), to: fmt(last));
      case _SummaryRange.year:
        return (
          from: fmt(DateTime(now.year, 1, 1)),
          to: fmt(DateTime(now.year, 12, 31)),
        );
      case _SummaryRange.all:
        return (from: null, to: null);
    }
  }
}

/// Live summary card — range chips + per-account totals from
/// `GET /v1/accounts/:id/summary`. Range defaults to "this month".
/// Per spec §03/§2.7 the per-account summary counts transfers — that's
/// intentional, transfers move the balance.
class _LiveSummaryCard extends StatefulWidget {
  const _LiveSummaryCard({required this.accountId});
  final String accountId;

  @override
  State<_LiveSummaryCard> createState() => _LiveSummaryCardState();
}

class _LiveSummaryCardState extends State<_LiveSummaryCard> {
  _SummaryRange _range = _SummaryRange.month;
  late Future<TransactionsSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<TransactionsSummary> _fetch() {
    final repo = context.read<TransactionsRepository>();
    final r = _range.toRange(DateTime.now());
    return repo.summaryForAccount(
      accountId: widget.accountId,
      from: r.from,
      to: r.to,
    );
  }

  void _setRange(_SummaryRange r) {
    if (r == _range) return;
    setState(() {
      _range = r;
      _future = _fetch();
    });
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.accountDetailSummaryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _rangeChip(l.transactionsRangeWeek, _SummaryRange.week),
                _rangeChip(l.transactionsRangeMonth, _SummaryRange.month),
                _rangeChip(l.transactionsRangeYear, _SummaryRange.year),
                _rangeChip(l.transactionsRangeAll, _SummaryRange.all),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<TransactionsSummary>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text(
                    snap.error.toString(),
                    style: TextStyle(color: scheme.error),
                  );
                }
                final s = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryStat(
                            label: l.accountDetailSummaryIncome,
                            amount: s.totalIncome,
                          ),
                        ),
                        Expanded(
                          child: _SummaryStat(
                            label: l.accountDetailSummaryExpense,
                            amount: s.totalExpense,
                          ),
                        ),
                        Expanded(
                          child: _SummaryStat(
                            label: l.accountDetailSummaryNet,
                            amount: s.net,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l.accountDetailSummaryTransactions(s.transactionCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(String label, _SummaryRange r) {
    return ChoiceChip(
      label: Text(label),
      selected: _range == r,
      onSelected: (_) => _setRange(r),
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

/// Live transactions section — top N transactions for this account
/// pulled from the global [TransactionsCubit] cache. Phase 1a renders
/// up to 20 rows; pagination / "View all" deferred to the dedicated
/// transactions list page (P1b).
class _LiveTransactionsSection extends StatefulWidget {
  const _LiveTransactionsSection({required this.accountId});
  final String accountId;

  @override
  State<_LiveTransactionsSection> createState() =>
      _LiveTransactionsSectionState();
}

class _LiveTransactionsSectionState extends State<_LiveTransactionsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Load filtered to this account so the cubit's hasMore / pagination
      // tracks the right slice. The detail page is the only consumer
      // that scopes by account, so a load() (not loadIfNeeded) is the
      // safe call — cache may have been loaded for a different account.
      context.read<TransactionsCubit>().load(accountId: widget.accountId);
    });
  }

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
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<TransactionsCubit, TransactionsState>(
              builder: (context, state) {
                final isLoading = state.status == TransactionsStatus.loading &&
                    state.transactions.isEmpty;
                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final rows = context
                    .read<TransactionsCubit>()
                    .forAccount(widget.accountId);
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    child: EmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: l.transactionsEmptyAccountTitle,
                      message: l.transactionsEmptyAccountMessage,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final tx in rows)
                      _TransactionRow(tx: tx),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signed = tx.signedAmount;
    final isCredit = signed > 0;
    final color = isCredit ? Colors.green.shade400 : scheme.error;
    final sign = signed > 0 ? '+' : (signed < 0 ? '−' : '');
    final categoryName = tx.type == TransactionType.transfer
        ? (tx.category?.name ?? '')
        : (tx.category?.name ?? '');
    return InkWell(
      onTap: () => GoRouter.of(context).push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              _iconForType(tx.type),
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName.isNotEmpty
                        ? categoryName
                        : (tx.note ?? '—'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        tx.date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      if (tx.tags.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.sell_outlined,
                            size: 12, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${tx.tags.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(TransactionType t) {
    return switch (t) {
      TransactionType.expense => Icons.south,
      TransactionType.income => Icons.north,
      TransactionType.transfer => Icons.swap_horiz,
    };
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

/// Result of the adjust-balance dialog. Returned via `Navigator.pop` so
/// the caller can issue the API call from outside the dialog's lifecycle.
class _AdjustBalanceResult {
  const _AdjustBalanceResult({required this.newBalance, this.note});
  final double newBalance;
  final String? note;
}

class _AdjustBalanceDialog extends StatefulWidget {
  const _AdjustBalanceDialog({required this.account});
  final Account account;

  @override
  State<_AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<_AdjustBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balanceController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: widget.account.balance.toString(),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.accountAdjustBalanceTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.accountAdjustBalanceBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${l.accountAdjustBalanceCurrentLabel}: ${CurrencyFormatter.format(widget.account.balance)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _balanceController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: l.accountAdjustBalanceNewLabel,
                prefixText: '฿ ',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null) {
                  return l.accountAdjustBalanceInvalidAmount;
                }
                if (parsed == widget.account.balance) {
                  return l.accountAdjustBalanceNoChange;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l.accountAdjustBalanceNoteLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final newBalance = double.parse(_balanceController.text.trim());
            final note = _noteController.text.trim();
            Navigator.of(context).pop(_AdjustBalanceResult(
              newBalance: newBalance,
              note: note.isEmpty ? null : note,
            ));
          },
          child: Text(l.accountAdjustBalanceConfirm),
        ),
      ],
    );
  }
}
