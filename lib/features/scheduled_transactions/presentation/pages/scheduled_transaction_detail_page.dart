import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_history.dart';
import '../../domain/scheduled_transaction.dart';
import '../cubit/scheduled_transactions_cubit.dart';

/// `/scheduled-transactions/:id` — read-only detail.
///
/// Shows hero (next billing date · amount · variant pill) + lifecycle
/// actions (Pause/Resume/Cancel/Generate Now) + previously-generated
/// transactions history.
class ScheduledTransactionDetailPage extends StatelessWidget {
  const ScheduledTransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduledTransactionsCubit,
        ScheduledTransactionsState>(
      builder: (context, state) {
        if (state.entries.isEmpty &&
            state.status == ScheduledTransactionsStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final entry =
            context.read<ScheduledTransactionsCubit>().byId(id);
        if (entry == null) return _NotFoundScaffold();
        return _LoadedScaffold(entry: entry);
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
        title: l.scheduledDetailNotFound,
        message: l.scheduledDetailNotFoundMessage,
      ),
    );
  }
}

class _LoadedScaffold extends StatefulWidget {
  const _LoadedScaffold({required this.entry});
  final ScheduledTransaction entry;

  @override
  State<_LoadedScaffold> createState() => _LoadedScaffoldState();
}

class _LoadedScaffoldState extends State<_LoadedScaffold> {
  late Future<ScheduledHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture =
        context.read<ScheduledTransactionsCubit>().history(widget.entry.id);
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture =
          context.read<ScheduledTransactionsCubit>().history(widget.entry.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        actions: [
          PopupMenuButton<_OverflowAction>(
            onSelected: (action) => _onMenuAction(context, l, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _OverflowAction.edit,
                child: Row(children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.scheduledDetailEdit),
                ]),
              ),
              if (entry.canPause)
                PopupMenuItem(
                  value: _OverflowAction.pause,
                  child: Row(children: [
                    const Icon(Icons.pause_circle_outline),
                    const SizedBox(width: AppSpacing.md),
                    Text(l.scheduledDetailPause),
                  ]),
                ),
              if (entry.canResume)
                PopupMenuItem(
                  value: _OverflowAction.resume,
                  child: Row(children: [
                    const Icon(Icons.play_circle_outline),
                    const SizedBox(width: AppSpacing.md),
                    Text(l.scheduledDetailResume),
                  ]),
                ),
              if (entry.canCancel)
                PopupMenuItem(
                  value: _OverflowAction.cancel,
                  child: Row(children: [
                    const Icon(Icons.cancel_outlined),
                    const SizedBox(width: AppSpacing.md),
                    Text(l.scheduledDetailCancel),
                  ]),
                ),
              PopupMenuItem(
                value: _OverflowAction.delete,
                child: Row(children: [
                  const Icon(Icons.delete_outline),
                  const SizedBox(width: AppSpacing.md),
                  Text(l.scheduledDetailDelete),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Hero(entry: entry),
          const SizedBox(height: AppSpacing.lg),
          _StatsCard(entry: entry),
          if (entry.canGenerateNow) ...[
            const SizedBox(height: AppSpacing.lg),
            _GenerateNowCard(entry: entry, onGenerated: _refreshHistory),
          ],
          const SizedBox(height: AppSpacing.lg),
          _HistorySection(future: _historyFuture),
        ],
      ),
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    AppLocalizations l,
    _OverflowAction action,
  ) async {
    final entry = widget.entry;
    switch (action) {
      case _OverflowAction.edit:
        context.push('/scheduled-transactions/${entry.id}/edit');
      case _OverflowAction.pause:
        await _runWithSnackbar(
          context,
          (cubit) => cubit.pause(entry.id),
        );
      case _OverflowAction.resume:
        await _runWithSnackbar(
          context,
          (cubit) => cubit.resume(entry.id),
        );
      case _OverflowAction.cancel:
        await _confirmAndRun(
          context,
          l,
          title: l.scheduledCancelConfirmTitle,
          body: l.scheduledCancelConfirmBody,
          action: l.scheduledCancelConfirmAction,
          run: (cubit) => cubit.cancel(entry.id),
          popOnSuccess: true,
        );
      case _OverflowAction.delete:
        await _confirmAndRun(
          context,
          l,
          title: l.scheduledDeleteConfirmTitle,
          body: l.scheduledDeleteConfirmBody,
          action: l.scheduledDeleteConfirmAction,
          run: (cubit) => cubit.remove(entry.id),
          popOnSuccess: true,
        );
    }
  }

  Future<void> _runWithSnackbar(
    BuildContext context,
    Future<void> Function(ScheduledTransactionsCubit cubit) run,
  ) async {
    final cubit = context.read<ScheduledTransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run(cubit);
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    AppLocalizations l, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function(ScheduledTransactionsCubit cubit) run,
    required bool popOnSuccess,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final cubit = context.read<ScheduledTransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await run(cubit);
      if (popOnSuccess && router.canPop()) router.pop();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

enum _OverflowAction { edit, pause, resume, cancel, delete }

class _Hero extends StatelessWidget {
  const _Hero({required this.entry});
  final ScheduledTransaction entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = entry.iconCode?.accentColorFor(palette) ?? scheme.primary;
    final amountColor = entry.type == ScheduledTransactionType.income
        ? Colors.green
        : accent;
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
            Row(
              children: [
                IconDisplay(
                  type: IconType.category,
                  size: 56,
                  iconCode: entry.iconCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        _StatusPill(status: entry.status),
                        const SizedBox(width: AppSpacing.sm),
                        _VariantPill(entry: entry),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              CurrencyFormatter.format(entry.amount),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.scheduledDetailNextDue(entry.nextBillingDate),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ScheduledStatus status;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      ScheduledStatus.active => (Colors.green, l.scheduledStatusActive),
      ScheduledStatus.paused => (Colors.orange, l.scheduledStatusPaused),
      ScheduledStatus.completed => (
          scheme.onSurfaceVariant,
          l.scheduledStatusCompleted
        ),
      ScheduledStatus.cancelled => (scheme.error, l.scheduledStatusCancelled),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _VariantPill extends StatelessWidget {
  const _VariantPill({required this.entry});
  final ScheduledTransaction entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final label = entry.isLoan
        ? l.scheduledVariantLoan
        : entry.isInstallment
            ? l.scheduledVariantInstallment
            : l.scheduledVariantRecurring;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.entry});
  final ScheduledTransaction entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              icon: Icons.account_balance_wallet_outlined,
              label: l.scheduledDetailAccount,
              value: entry.account?.name ?? '—',
            ),
            if (entry.category != null)
              _StatRow(
                icon: Icons.category_outlined,
                label: l.scheduledDetailCategory,
                value: entry.category!.name,
              ),
            _StatRow(
              icon: Icons.cached,
              label: l.scheduledDetailCycle,
              value: _cycleLabel(l, entry.billingCycle),
            ),
            if (entry.isInstallment) ...[
              if (entry.totalAmount != null)
                _StatRow(
                  icon: Icons.payments_outlined,
                  label: l.scheduledDetailTotalAmount,
                  value: CurrencyFormatter.format(entry.totalAmount!),
                ),
              if (entry.downPayment != null && entry.downPayment! > 0)
                _StatRow(
                  icon: Icons.south_outlined,
                  label: l.scheduledDetailDownPayment,
                  value: CurrencyFormatter.format(entry.downPayment!),
                ),
              if (entry.totalInstallments != null)
                _StatRow(
                  icon: Icons.format_list_numbered,
                  label: l.scheduledDetailInstallments,
                  value: l.scheduledInstallmentsLeft(
                    entry.remainingInstallments ?? 0,
                    entry.totalInstallments!,
                  ),
                ),
              if (entry.interestRate != null && entry.interestRate! > 0)
                _StatRow(
                  icon: Icons.percent,
                  label: l.scheduledDetailInterestRate,
                  value: '${entry.interestRate!.toStringAsFixed(2)}%',
                ),
            ],
            if (entry.note != null && entry.note!.isNotEmpty)
              _StatRow(
                icon: Icons.sticky_note_2_outlined,
                label: l.scheduledDetailNote,
                value: entry.note!,
              ),
          ],
        ),
      ),
    );
  }

  String _cycleLabel(AppLocalizations l, BillingCycle c) {
    switch (c) {
      case BillingCycle.daily:
        return l.scheduledCycleDaily;
      case BillingCycle.weekly:
        return l.scheduledCycleWeekly;
      case BillingCycle.monthly:
        return l.scheduledCycleMonthly;
      case BillingCycle.yearly:
        return l.scheduledCycleYearly;
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateNowCard extends StatefulWidget {
  const _GenerateNowCard({required this.entry, required this.onGenerated});
  final ScheduledTransaction entry;
  final VoidCallback onGenerated;

  @override
  State<_GenerateNowCard> createState() => _GenerateNowCardState();
}

class _GenerateNowCardState extends State<_GenerateNowCard> {
  bool _busy = false;

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
              l.scheduledGenerateNowTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.scheduledGenerateNowBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _busy ? null : _trigger,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt),
                label: Text(l.scheduledGenerateNowAction),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _trigger() async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ScheduledTransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final result = await cubit.generateNow(widget.entry.id);
      widget.onGenerated();
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.scheduledGenerateNowSuccess),
          action: SnackBarAction(
            label: l.scheduledGenerateNowViewTransaction,
            onPressed: () => router.push(
              '/transactions/${result.generatedTransactionId}',
            ),
          ),
        ));
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.future});
  final Future<ScheduledHistory> future;

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
              l.scheduledDetailHistoryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<ScheduledHistory>(
              future: future,
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
                final h = snap.data!;
                if (h.entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    child: Text(
                      l.scheduledDetailHistoryEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final e in h.entries)
                      InkWell(
                        onTap: () => GoRouter.of(context)
                            .push('/transactions/${e.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 20,
                                  color: scheme.onSurfaceVariant),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  e.date,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(e.amount),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (h.totalGenerated > 0) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.scheduledDetailHistoryTotal(h.totalGenerated),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                  h.totalAmountGenerated),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
