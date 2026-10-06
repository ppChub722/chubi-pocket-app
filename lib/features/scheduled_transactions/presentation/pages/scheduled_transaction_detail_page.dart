import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_history.dart';
import '../../domain/scheduled_transaction.dart';
import '../cubit/scheduled_transactions_cubit.dart';

/// `/scheduled-transactions/:id`: header (icon · name · status pill ·
/// variant · amount · next due) → stats → "สร้างตอนนี้" → history. Top bar
/// `[🗑 ลบ][✏️]`; pause / resume / cancel live on the status pill (§1.5).
class ScheduledTransactionDetailPage extends StatelessWidget {
  const ScheduledTransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduledTransactionsCubit, ScheduledTransactionsState>(
      builder: (context, state) {
        final entry = context.read<ScheduledTransactionsCubit>().byId(id);
        if (entry != null) return _LoadedScaffold(entry: entry);
        return Scaffold(
          appBar: AppTopBar(title: l.scheduledTitle, showBack: true),
          body: state.status == ScheduledTransactionsStatus.loading
              ? const LoadingView()
              : EmptyView(
                  icon: AppIcons.empty,
                  title: l.scheduledDetailNotFound,
                  message: l.scheduledDetailNotFoundMessage,
                ),
        );
      },
    );
  }
}

class _LoadedScaffold extends StatefulWidget {
  const _LoadedScaffold({required this.entry});
  final ScheduledTransaction entry;

  @override
  State<_LoadedScaffold> createState() => _LoadedScaffoldState();
}

enum _StatusAction { pause, resume, cancel }

class _LoadedScaffoldState extends State<_LoadedScaffold> {
  late Future<ScheduledHistory> _historyFuture =
      context.read<ScheduledTransactionsCubit>().history(widget.entry.id);

  void _refreshHistory() => setState(() {
        _historyFuture =
            context.read<ScheduledTransactionsCubit>().history(widget.entry.id);
      });

  Future<void> _changeStatus() async {
    final l = AppLocalizations.of(context)!;
    final e = widget.entry;
    final action = await showOptionSheet<_StatusAction>(
      context,
      title: l.scheduledStatusChangeTitle,
      options: [
        if (e.canPause)
          SheetOption(
              value: _StatusAction.pause,
              label: l.scheduledDetailPause,
              leading: const Icon(Icons.pause_circle_outline)),
        if (e.canResume)
          SheetOption(
              value: _StatusAction.resume,
              label: l.scheduledDetailResume,
              leading: const Icon(Icons.play_circle_outline)),
        if (e.canCancel)
          SheetOption(
              value: _StatusAction.cancel,
              label: l.scheduledDetailCancel,
              leading: const Icon(Icons.cancel_outlined)),
      ],
    );
    if (action == null || !mounted) return;
    final cubit = context.read<ScheduledTransactionsCubit>();
    switch (action) {
      case _StatusAction.pause:
        await _run(() => cubit.pause(e.id));
      case _StatusAction.resume:
        await _run(() => cubit.resume(e.id));
      case _StatusAction.cancel:
        final ok = await showConfirmDialog(
          context,
          title: l.scheduledCancelConfirmTitle,
          message: l.scheduledCancelConfirmBody,
          confirmLabel: l.scheduledCancelConfirmAction,
          destructive: true,
        );
        if (ok) await _run(() => cubit.cancel(e.id));
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.scheduledDeleteConfirmTitle,
      message: l.scheduledDeleteConfirmBody,
      confirmLabel: l.scheduledDeleteConfirmAction,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final router = GoRouter.of(context);
    await _run(
      () => context.read<ScheduledTransactionsCubit>().remove(widget.entry.id),
      then: () {
        if (router.canPop()) router.pop();
      },
    );
  }

  Future<void> _run(Future<void> Function() action, {VoidCallback? then}) async {
    try {
      await action();
      then?.call();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entry = widget.entry;
    final canChange = entry.canPause || entry.canResume || entry.canCancel;
    return Scaffold(
      appBar: AppTopBar(
        title: entry.name,
        showBack: true,
        actions: [
          AppBarAction(
            icon: AppIcons.delete,
            tooltip: l.scheduledDetailDelete,
            destructive: true,
            onPressed: _delete,
          ),
          AppBarAction(
            icon: AppIcons.edit,
            tooltip: l.scheduledDetailEdit,
            onPressed: () =>
                context.push('/scheduled-transactions/${entry.id}/edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        children: [
          _Hero(entry: entry, onStatusTap: canChange ? _changeStatus : null),
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
}

class _Hero extends StatelessWidget {
  const _Hero({required this.entry, required this.onStatusTap});
  final ScheduledTransaction entry;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = entry.iconCode?.accentColorFor(palette) ?? palette.primary;
    final isIncome = entry.type == ScheduledTransactionType.income;
    final (tone, label) = switch (entry.status) {
      ScheduledStatus.active => (Tone.success, l.scheduledStatusActive),
      ScheduledStatus.paused => (Tone.warning, l.scheduledStatusPaused),
      ScheduledStatus.completed => (Tone.neutral, l.scheduledStatusCompleted),
      ScheduledStatus.cancelled => (Tone.danger, l.scheduledStatusCancelled),
    };
    return HeaderCard(
      accent: accent,
      leading:
          IconDisplay(type: IconType.category, size: 52, iconCode: entry.iconCode),
      title: Text(entry.name),
      subtitle: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusPill(label: label, tone: tone, dense: true, onTap: onStatusTap),
          _VariantPill(entry: entry),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyText(
            entry.amount,
            tone: isIncome ? MoneyTone.income : MoneyTone.plain,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(l.scheduledDetailNextDue(entry.nextBillingDate),
              style: Theme.of(context).textTheme.bodySmall),
        ],
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
                  value: moneyString(context, entry.totalAmount!),
                ),
              if (entry.downPayment != null && entry.downPayment! > 0)
                _StatRow(
                  icon: Icons.south_outlined,
                  label: l.scheduledDetailDownPayment,
                  value: moneyString(context, entry.downPayment!),
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
                                moneyString(context, e.amount),
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
                              moneyString(context, 
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
