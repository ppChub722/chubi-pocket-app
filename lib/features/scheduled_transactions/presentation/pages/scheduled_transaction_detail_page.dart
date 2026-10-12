import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/top_bar_crumbs.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/wallet_value_chip.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../domain/scheduled_enums.dart';
import '../../domain/scheduled_history.dart';
import '../../domain/scheduled_transaction.dart';
import '../cubit/scheduled_transactions_cubit.dart';

/// `/scheduled-transactions/:id` — view only: header (icon · name · status
/// pill · variant · amount · next due) → stats → "สร้างตอนนี้" → history →
/// delete. ✏️ on the header opens the quick create sheet in scheduled mode;
/// pause / resume / cancel live on the status pill (§1.5). No in-place
/// edit mode, so delete is always the last row (as on transaction detail).
class ScheduledTransactionDetailPage extends StatefulWidget {
  const ScheduledTransactionDetailPage({required this.id, super.key});

  final String id;

  @override
  State<ScheduledTransactionDetailPage> createState() =>
      _ScheduledTransactionDetailPageState();
}

class _ScheduledTransactionDetailPageState
    extends State<ScheduledTransactionDetailPage> {
  /// Last entry shown. After delete (the row below) the cubit drops it
  /// while this page is still animating away — keep painting it instead of
  /// flashing "not found".
  ScheduledTransaction? _last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduledTransactionsCubit, ScheduledTransactionsState>(
      builder: (context, state) {
        final entry =
            context.read<ScheduledTransactionsCubit>().byId(widget.id) ?? _last;
        if (entry != null) {
          _last = entry;
          return _LoadedScaffold(entry: entry);
        }
        return Scaffold(
          appBar: AppTopBar(title: l.scheduledTitle, showBack: true),
          extendBodyBehindAppBar: true,
          body: AsyncStateView.fallback(
            loading: state.status == ScheduledTransactionsStatus.loading,
            error: state.error,
            onRetry: context.read<ScheduledTransactionsCubit>().load,
            notFound: EmptyView(
              icon: AppIcons.empty,
              title: l.scheduledDetailNotFound,
              message: l.scheduledDetailNotFoundMessage,
            ),
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
  late Future<ScheduledHistory> _historyFuture = context
      .read<ScheduledTransactionsCubit>()
      .history(widget.entry.id);

  void _refreshHistory() => setState(() {
    _historyFuture = context.read<ScheduledTransactionsCubit>().history(
      widget.entry.id,
    );
  });

  /// Pull to refresh: the entry (via the list) and its history.
  Future<void> _refresh() async {
    _refreshHistory();
    // Never throw out of the callback: the cubit emits its own error state and
    // the history section shows its own error.
    await Future.wait([
      context.read<ScheduledTransactionsCubit>().load().catchError((_) {}),
      _historyFuture.then<void>((_) {}, onError: (_) {}),
    ]);
  }

  /// Applies a status option picked in the hero's popover.
  Future<void> _changeStatus(_StatusAction action) async {
    final l = AppLocalizations.of(context)!;
    final e = widget.entry;
    if (!mounted) return;
    final cubit = context.read<ScheduledTransactionsCubit>();
    switch (action) {
      case _StatusAction.pause:
        if (e.canPause) await _run(() => cubit.pause(e.id));
      case _StatusAction.resume:
        if (e.canResume) await _run(() => cubit.resume(e.id));
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

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
    }
  }

  /// Delete, then land on the list — pop back to it when it's in the
  /// stack, else go there. The page keeps painting the last entry while it
  /// animates away (see [_ScheduledTransactionDetailPageState._last]).
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
    try {
      await context.read<ScheduledTransactionsCubit>().remove(widget.entry.id);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    goToCrumb(
      context,
      TopBarCrumb(
        label: l.moreScheduled,
        path: '/scheduled-transactions',
        routeName: 'scheduled-transactions',
      ),
    );
  }

  void _edit() => showQuickCreateSheet(
    context,
    scheduled: true,
    scheduledEntry: widget.entry,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entry = widget.entry;
    final canChange = entry.canPause || entry.canResume || entry.canCancel;
    return Scaffold(
      appBar: AppTopBar(title: entry.name, showBack: true),
      extendBodyBehindAppBar: true,
      // Builder: the body's context sees the bar height in padding.top.
      body: Builder(
        builder: (context) => DetailPageBody(
          onRefresh: _refresh,
          physics: const AlwaysScrollableScrollPhysics(),
          topInset: MediaQuery.paddingOf(context).top + AppSpacing.md,
          bottomInset: 96 + MediaQuery.paddingOf(context).bottom,
          hero: _Hero(
            entry: entry,
            onStatusSelected: canChange ? _changeStatus : null,
            onEdit: _edit,
          ),
          sections: [
            (first) => _StatsCard(entry: entry, onEdit: _edit, first: first),
            (first) => entry.canGenerateNow
                ? _GenerateNowCard(
                    entry: entry,
                    onGenerated: _refreshHistory,
                    first: first,
                  )
                : null,
            (first) => _HistorySection(future: _historyFuture, first: first),
          ],
          manage: ManageSection(
            deleteLabel: l.scheduledDeleteThis,
            onDelete: _delete,
          ),
          metaLines: detailMetaLines(
            context,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({
    required this.entry,
    required this.onStatusSelected,
    required this.onEdit,
  });
  final ScheduledTransaction entry;

  /// Null = the status can't be changed (the chip is display only).
  final ValueChanged<_StatusAction>? onStatusSelected;
  final VoidCallback onEdit;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  // Read-only view of the description for HeroDescription.
  late final _descriptionCtrl = TextEditingController(
    text: widget.entry.description ?? '',
  );

  @override
  void didUpdateWidget(_Hero old) {
    super.didUpdateWidget(old);
    final v = widget.entry.description ?? '';
    if (_descriptionCtrl.text != v) _descriptionCtrl.text = v;
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final onStatusSelected = widget.onStatusSelected;
    final onEdit = widget.onEdit;
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = entry.iconCode.tintFor(palette);
    final isIncome = entry.type == ScheduledTransactionType.income;
    final (tone, label) = switch (entry.status) {
      ScheduledStatus.active => (AppChipTone.success, l.scheduledStatusActive),
      ScheduledStatus.paused => (AppChipTone.warning, l.scheduledStatusPaused),
      ScheduledStatus.completed => (
        AppChipTone.neutral,
        l.scheduledStatusCompleted,
      ),
      ScheduledStatus.cancelled => (
        AppChipTone.danger,
        l.scheduledStatusCancelled,
      ),
    };
    final variant = entry.isLoan
        ? l.scheduledVariantLoan
        : entry.isInstallment
        ? l.scheduledVariantInstallment
        : l.scheduledVariantRecurring;
    return HeaderCard(
      accent: accent,
      glyph: AppIcons.scheduled,
      onEdit: onEdit,
      leading: IconDisplay(
        type: IconType.category,
        size: 52,
        iconCode: entry.iconCode,
      ),
      title: Text(entry.name),
      description: HeroDescription(
        controller: _descriptionCtrl,
        editing: false,
        hint: l.commonDescription,
        onEnterEdit: onEdit,
      ),
      topRow: [
        // The status chip anchors a popover: the current status is
        // highlighted (choosing it again does nothing); the others show
        // only while their transition is allowed.
        OptionMenuAnchor<_StatusAction>(
          selected: switch (entry.status) {
            ScheduledStatus.active => _StatusAction.resume,
            ScheduledStatus.paused => _StatusAction.pause,
            _ => null,
          },
          options: [
            if (entry.canPause || entry.status == ScheduledStatus.paused)
              SheetOption(
                value: _StatusAction.pause,
                label: l.scheduledDetailPause,
                leading: const _ToneIcon(AppIcons.pause, Tone.warning),
              ),
            if (entry.canResume || entry.status == ScheduledStatus.active)
              SheetOption(
                value: _StatusAction.resume,
                label: l.scheduledDetailResume,
                leading: const _ToneIcon(AppIcons.resume, Tone.success),
              ),
            if (entry.canCancel)
              SheetOption(
                value: _StatusAction.cancel,
                label: l.scheduledDetailCancel,
                leading: const _ToneIcon(AppIcons.stop, Tone.danger),
              ),
          ],
          onSelected: (a) => onStatusSelected?.call(a),
          builder: (context, toggle) => AppChip(
            label: label,
            dot: true,
            tone: tone,
            selected: true,
            trailing: onStatusSelected != null
                ? AppChipTrailing.dropdown
                : AppChipTrailing.none,
            onTap: onStatusSelected != null ? toggle : null,
          ),
        ),
        AppChip(label: variant, tone: AppChipTone.neutral, selected: true),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyText(
            entry.amount,
            tone: isIncome ? MoneyTone.income : MoneyTone.plain,
            style: AppTypography.of(context, AppTextRole.display),
          ),
          AppText(
            l.scheduledDetailNextDue(entry.nextBillingDate),
            role: AppTextRole.caption,
          ),
        ],
      ),
    );
  }
}

/// A status-change option's icon (⏸ / ▶ / ⏹), tinted with the tone of the
/// status it leads to.
class _ToneIcon extends StatelessWidget {
  const _ToneIcon(this.icon, this.tone);
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) =>
      AppIcon(icon, size: AppIconSize.lg, color: tone.color(context));
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.entry,
    required this.onEdit,
    required this.first,
  });
  final ScheduledTransaction entry;
  final VoidCallback onEdit;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = <Widget>[
      // Empty → tapping opens the same edit sheet as ✏️ (no in-place edit).
      DetailRow.pick(
        leading: const AppIcon(AppIcons.wallet),
        label: l.scheduledDetailAccount,
        valueChip: entry.account == null
            ? null
            : walletValueChip(
                context,
                name: entry.account!.name,
                iconCode: entry.account!.iconCode,
              ),
        emptyText: l.quickEventNone,
        onTap: entry.account == null ? onEdit : null,
      ),
      DetailRow.pick(
        leading: const AppIcon(AppIcons.category),
        label: l.scheduledDetailCategory,
        // The embedded ref only (no category list here): one chip with the
        // category's own icon + colour.
        valueChip: entry.category == null
            ? null
            : ChipPath(
                segments: [
                  ChipPathSegment(
                    label: entry.category!.name,
                    icon: IconRegistry.get(
                      entry.category!.iconCode?.icon,
                      fallback: AppIcons.category,
                    ),
                    color: entry.category!.iconCode.tintFor(
                      Theme.of(context).extension<AppColors>()!,
                    ),
                  ),
                ],
              ),
        emptyText: l.quickEventNone,
        onTap: entry.category == null ? onEdit : null,
      ),
      _StatRow(
        icon: AppIcons.scheduled,
        label: l.scheduledDetailCycle,
        value: _cycleLabel(l, entry.billingCycle),
      ),
      if (entry.isInstallment) ...[
        if (entry.totalAmount != null)
          _StatRow(
            icon: AppIcons.cash,
            label: l.scheduledDetailTotalAmount,
            value: moneyString(context, entry.totalAmount!),
          ),
        if (entry.downPayment != null && entry.downPayment! > 0)
          _StatRow(
            icon: AppIcons.trendDown,
            label: l.scheduledDetailDownPayment,
            value: moneyString(context, entry.downPayment!),
          ),
        if (entry.totalInstallments != null)
          _StatRow(
            icon: AppIcons.transactions,
            label: l.scheduledDetailInstallments,
            value: l.scheduledInstallmentsLeft(
              entry.remainingInstallments ?? 0,
              entry.totalInstallments!,
            ),
          ),
        if (entry.interestRate != null && entry.interestRate! > 0)
          _StatRow(
            icon: AppIcons.trendUp,
            label: l.scheduledDetailInterestRate,
            value: '${entry.interestRate!.toStringAsFixed(2)}%',
          ),
      ],
      // Long text: label on top, value full-width below. (The description
      // lives in the hero.)
      _TextRow(label: l.commonNote, value: entry.note, onLongPress: onEdit),
    ];
    // Detail-page rows (SectionCard / DetailRow), hairlines between.
    return SectionCard(first: first, children: rows);
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

  /// A [DetailRow] — the shared detail-page row.
  @override
  Widget build(BuildContext context) =>
      DetailRow(leading: AppIcon(icon), label: label, trailing: AppText(value));
}

/// Description / note — a [DetailStacked], so long text wraps full-width.
class _TextRow extends StatelessWidget {
  const _TextRow({required this.label, required this.value, this.onLongPress});

  final String label;
  final String? value;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.trim().isEmpty;
    final l = AppLocalizations.of(context)!;
    return DetailStacked(
      label: label,
      onLongPress: onLongPress,
      child: empty
          ? DetailPlaceholder(l.commonLongPressToEdit)
          : AppText(value!),
    );
  }
}

class _GenerateNowCard extends StatefulWidget {
  const _GenerateNowCard({
    required this.entry,
    required this.onGenerated,
    required this.first,
  });
  final ScheduledTransaction entry;
  final VoidCallback onGenerated;
  final bool first;

  @override
  State<_GenerateNowCard> createState() => _GenerateNowCardState();
}

class _GenerateNowCardState extends State<_GenerateNowCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SectionCard(
      first: widget.first,
      // One block — the row and its button belong together.
      dividers: false,
      children: [
        DetailRow(
          leading: const AppIcon(AppIcons.add),
          label: l.scheduledGenerateNowTitle,
          helper: l.scheduledGenerateNowBody,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: l.scheduledGenerateNowAction,
              icon: AppIcons.add,
              loading: _busy,
              onPressed: _trigger,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _trigger() async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ScheduledTransactionsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final open = pageOpener(context);
    setState(() => _busy = true);
    try {
      final result = await cubit.generateNow(widget.entry.id);
      // The generated transaction moved a wallet — refresh balances (the
      // dashboard reloads off this too).
      // (home marks the dashboard stale off the AccountsCubit emit.)
      if (mounted) {
        final accounts = context.read<AccountsCubit>();
        if (result.accountBalances.isEmpty) {
          unawaited(accounts.load());
        } else {
          accounts.patchBalances(result.accountBalances);
        }
      }
      widget.onGenerated();
      if (!mounted) return;
      showAppSnackBarOn(
        messenger,
        l.scheduledGenerateNowSuccess,
        tone: Tone.success,
        actionLabel: l.scheduledGenerateNowViewTransaction,
        onAction: () => open('/transactions/${result.generatedTransactionId}'),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBarOn(messenger, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.future, required this.first});
  final Future<ScheduledHistory> future;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // Each history entry is its own row, so the section draws the
    // hairlines between them (and above the total).
    Widget row(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: child,
    );

    return FutureBuilder<ScheduledHistory>(
      future: future,
      builder: (context, snap) {
        final List<Widget> rows;
        if (snap.connectionState != ConnectionState.done) {
          // Rows shaped like the history rows below.
          rows = [
            for (var i = 0; i < 3; i++)
              row(
                const Row(
                  children: [
                    SkeletonCircle(size: 20),
                    SizedBox(width: AppSpacing.md),
                    Expanded(child: SkeletonLine()),
                    SizedBox(width: AppSpacing.xl),
                    SkeletonLine(width: 64),
                  ],
                ),
              ),
          ];
        } else if (snap.hasError) {
          rows = [
            row(
              AppMessage(
                tone: Tone.danger,
                message: ErrorView.titleFor(
                  context,
                  ApiException.from(snap.error!, snap.stackTrace),
                ),
              ),
            ),
          ];
        } else if (snap.data!.entries.isEmpty) {
          rows = [row(DetailPlaceholder(l.scheduledDetailHistoryEmpty))];
        } else {
          final h = snap.data!;
          rows = [
            for (final e in h.entries)
              ListRow(
                title: e.date,
                leading: AppIcon(
                  AppIcons.transactions,
                  size: AppIconSize.md,
                  color: scheme.onSurfaceVariant,
                ),
                trailing: MoneyText(
                  e.amount,
                  style: AppTypography.of(
                    context,
                    AppTextRole.body,
                  )?.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () => openPage(context, '/transactions/${e.id}'),
              ),
            if (h.totalGenerated > 0)
              row(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      l.scheduledDetailHistoryTotal(h.totalGenerated),
                      role: AppTextRole.caption,
                    ),
                    AppText(
                      moneyString(context, h.totalAmountGenerated),
                      role: AppTextRole.caption,
                      color: scheme.onSurface,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
          ];
        }
        return SectionCard(
          first: first,
          title: l.scheduledDetailHistoryTitle,
          description: l.scheduledDetailHistoryDescription,
          children: rows,
        );
      },
    );
  }
}
