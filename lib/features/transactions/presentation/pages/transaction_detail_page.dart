import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';

/// Full-screen view of a single transaction. Routed at
/// `/transactions/:id`. Read-only by default; overflow menu offers
/// Edit (pushes the edit form) and Delete (confirm dialog → cascade
/// delete on transfers).
class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    // Defensive cache warm-up for deep-links.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final tx =
            context.read<TransactionsCubit>().byId(widget.transactionId);
        if (tx == null) {
          if (state.status == TransactionsStatus.loading ||
              state.status == TransactionsStatus.initial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _NotFoundScaffold();
        }
        return _Loaded(tx: tx);
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
        icon: Icons.receipt_long_outlined,
        title: l.transactionDetailNotFound,
        message: l.transactionDetailNotFoundMessage,
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // System-category rows on non-transfer transactions (Opening
    // Balance, Adjustment) are auto-created bookkeeping; they're
    // read-only in the UI to keep the audit trail honest. Transfer
    // rows DO carry a system category but have their own edit/delete
    // cascade path, so we still allow actions on them.
    final isSystemRow = tx.type != TransactionType.transfer &&
        tx.categoryId != null &&
        (context.read<CategoriesCubit>().byId(tx.categoryId!)?.isSystem ??
            false);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForType(l, tx.type)),
        actions: isSystemRow
            ? const []
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l.transactionDetailEdit,
                  onPressed: () => context.push('/transactions/${tx.id}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l.transactionDetailDelete,
                  onPressed: () => _confirmDelete(context, l, tx),
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        children: [
          _AmountHeader(tx: tx),
          if (isSystemRow) ...[
            const SizedBox(height: AppSpacing.lg),
            _SystemRowBanner(tx: tx),
          ],
          const SizedBox(height: AppSpacing.lg),
          _MetaCard(tx: tx),
          if (tx.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _TagsCard(tags: tx.tags),
          ],
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(note: tx.note!),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l, Transaction tx) async {
    final isTransfer = tx.type == TransactionType.transfer;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTransfer
            ? l.transactionDetailDeleteConfirmTitleTransfer
            : l.transactionDetailDeleteConfirmTitle),
        content: Text(isTransfer
            ? l.transactionDetailDeleteConfirmBodyTransfer
            : l.transactionDetailDeleteConfirmBody),
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
            child: Text(l.transactionDetailDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final txCubit = context.read<TransactionsCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    try {
      await txCubit.remove(tx.id);
      // Both balances move on transfer delete; one on single delete.
      // Cheapest correct path is a full reload — phase 1a doesn't have
      // enough volume for it to feel slow.
      await accountsCubit.load();
      if (router.canPop()) router.pop();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

String _titleForType(AppLocalizations l, TransactionType t) {
  switch (t) {
    case TransactionType.expense:
      return l.transactionTypeExpense;
    case TransactionType.income:
      return l.transactionTypeIncome;
    case TransactionType.transfer:
      return l.transactionTypeTransfer;
  }
}

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signed = tx.signedAmount;
    final color = signed > 0 ? Colors.green.shade400 : scheme.error;
    final sign = signed > 0 ? '+' : (signed < 0 ? '−' : '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              tx.date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _Row(
              icon: Icons.account_balance_wallet_outlined,
              label: l.transactionFormAccountLabel,
              value: tx.account?.name ?? tx.accountId,
            ),
            if (tx.type != TransactionType.transfer)
              _Row(
                icon: Icons.category_outlined,
                label: l.transactionFormCategoryLabel,
                value: tx.category?.name ?? l.transactionFormCategoryNone,
              ),
            if (tx.type == TransactionType.transfer)
              _Row(
                icon: Icons.swap_horiz,
                label: l.transactionTypeTransfer,
                value: tx.category?.name ?? '',
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
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

/// Read-only notice shown above the meta card on Opening-Balance and
/// Adjustment rows. Tells the user this row was auto-created and points
/// them at the account-level action that produced it (account edit or
/// Adjust balance). The banner is the *visible* counterpart to the BE
/// `SYSTEM_TRANSACTION_IMMUTABLE` rejection.
class _SystemRowBanner extends StatelessWidget {
  const _SystemRowBanner({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l.transactionDetailSystemRowBanner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _TagsCard extends StatelessWidget {
  const _TagsCard({required this.tags});
  final List<EmbeddedTag> tags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sell_outlined,
                size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in tags)
                    Chip(
                      label: Text(t.name),
                      avatar: t.color != null
                          ? CircleAvatar(
                              backgroundColor: _parseHex(t.color!),
                              radius: 6,
                            )
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `#RRGGBB` → [Color]. Falls back to grey for malformed values so a
  /// stray hex doesn't crash the chip render.
  Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final v = int.tryParse(clean, radix: 16);
    if (v == null) return Colors.grey;
    return Color(0xFF000000 | v);
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
            Icon(Icons.sticky_note_2_outlined,
                size: 20, color: scheme.onSurfaceVariant),
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
