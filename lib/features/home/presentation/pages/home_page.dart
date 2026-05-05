import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/domain/transactions_summary.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';

/// Dashboard. Three blocks (top to bottom):
/// 1. **Net worth** — sum of every active account's cached balance
///    (live, not API-aggregated).
/// 2. **This-month summary** — global `/v1/transactions/summary`,
///    `include_in_report` filter applied server-side. Range chips
///    (Week / Month / Year / All) reuse the account-detail pattern.
/// 3. **Recent transactions** — top 5 from the [TransactionsCubit]
///    cache. Tap → detail page.
///
/// Empty-state when both accounts and transactions are empty (fresh
/// user). The chrome (top bar / bottom nav / FAB) is owned by the shell.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Warm up everything the dashboard needs. Each cubit no-ops if
    // already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<TransactionsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accountsState) {
        return BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (context, txState) {
            final accountsLoading =
                accountsState.status == AccountsStatus.loading &&
                    accountsState.accounts.isEmpty;
            final txLoading =
                txState.status == TransactionsStatus.loading &&
                    txState.transactions.isEmpty;

            if (accountsLoading && txLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Cold-fresh user: nothing anywhere. Show the same empty
            // pattern Phase 0 had.
            if (accountsState.accounts.isEmpty &&
                txState.transactions.isEmpty) {
              return EmptyView(
                icon: Icons.savings_outlined,
                title: l.homeEmptyTitle,
                message: l.homeEmptyMessage,
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              children: [
                _NetWorthCard(accounts: accountsState.accounts),
                const SizedBox(height: AppSpacing.lg),
                const _MonthlySummaryCard(),
                const SizedBox(height: AppSpacing.lg),
                _RecentTransactions(transactions: txState.transactions),
                const SizedBox(height: AppSpacing.huge),
              ],
            );
          },
        );
      },
    );
  }
}

/// Sums active account balances. Phase 1 is single-currency (THB), so
/// the math is plain addition; multi-currency conversion is Phase 2.
class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.accounts});
  final List<dynamic> accounts; // List<Account>

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    double total = 0;
    for (final a in accounts) {
      total += (a.balance as double);
    }
    return Card(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.homeNetWorthLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CurrencyFormatter.format(total),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: total < 0 ? scheme.error : scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l.homeNetWorthAccountCount(accounts.length),
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

enum _SummaryRange { week, month, year, all }

extension on _SummaryRange {
  ({String? from, String? to}) toRange(DateTime now) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _SummaryRange.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (from: fmt(monday), to: fmt(sunday));
      case _SummaryRange.month:
        return (
          from: fmt(DateTime(now.year, now.month, 1)),
          to: fmt(DateTime(now.year, now.month + 1, 0)),
        );
      case _SummaryRange.year:
        return (
          from: fmt(DateTime(now.year, 1, 1)),
          to: fmt(DateTime(now.year, 12, 31)),
        );
      case _SummaryRange.all:
        // BE requires a range on the global summary; we send a far-past
        // start so "All" effectively means "everything tracked so far".
        return (from: '1970-01-01', to: fmt(today));
    }
  }
}

class _MonthlySummaryCard extends StatefulWidget {
  const _MonthlySummaryCard();

  @override
  State<_MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<_MonthlySummaryCard> {
  _SummaryRange _range = _SummaryRange.month;
  late Future<TransactionsSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<TransactionsSummary> _fetch() {
    final r = _range.toRange(DateTime.now());
    return context.read<TransactionsRepository>().summary(
          from: r.from!,
          to: r.to!,
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
            Text(
              l.accountDetailSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
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
                          child: _Stat(
                            label: l.accountDetailSummaryIncome,
                            amount: s.totalIncome,
                            kind: _StatKind.income,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            label: l.accountDetailSummaryExpense,
                            amount: s.totalExpense,
                            kind: _StatKind.expense,
                          ),
                        ),
                        Expanded(
                          child: _Stat(
                            label: l.accountDetailSummaryNet,
                            amount: s.net,
                            kind: _StatKind.net,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.amount, required this.kind});
  final String label;
  final double amount;
  final _StatKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (kind) {
      _StatKind.income => Colors.green.shade400,
      _StatKind.expense => scheme.error,
      _StatKind.net => amount > 0
          ? Colors.green.shade400
          : (amount < 0 ? scheme.error : scheme.onSurface),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

enum _StatKind { income, expense, net }

/// Shows the 5 most recent transactions from the cubit cache. Tap
/// "View all" → `/transactions`.
class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final recent = transactions.take(5).toList();
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
                  l.homeRecentTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: Text(l.homeRecentViewAll),
                ),
              ],
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  l.transactionsEmptyAccountMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              for (final tx in recent) _RecentRow(tx: tx),
          ],
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signed = tx.signedAmount;
    final amountColor = signed > 0 ? Colors.green.shade400 : scheme.error;
    final sign = signed > 0 ? '+' : (signed < 0 ? '−' : '');

    // Resolve category icon + accent color from CategoriesCubit cache.
    // Falls back to a type-based arrow if the category is missing
    // (uncategorized expense/income legacy rows; system categories that
    // aren't in the user's visible list).
    final cubit = context.watch<CategoriesCubit>();
    final cat = tx.category != null ? cubit.byId(tx.category!.id) : null;
    final iconData = cat?.icon.icon ?? _iconForType(tx.type);
    final fallbackColor = switch (tx.type) {
      TransactionType.expense => scheme.error,
      TransactionType.income => Colors.green.shade400,
      _ => scheme.onSurfaceVariant,
    };
    final iconColor = cat?.color.color ?? fallbackColor;

    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(iconData, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category?.name ?? (tx.note ?? '—'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${tx.account?.name ?? ''} · ${tx.date}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(TransactionType t) {
  return switch (t) {
    TransactionType.expense => Icons.remove,
    TransactionType.income => Icons.add,
    TransactionType.transfer => Icons.swap_horiz,
  };
}
