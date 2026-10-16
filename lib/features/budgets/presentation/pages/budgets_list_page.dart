import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../domain/budget.dart';
import '../../domain/budget_period.dart';
import '../budget_labels.dart';
import '../budget_summary_card.dart';
import '../cubit/budgets_cubit.dart';

/// `/budgets` — every budget at its CURRENT period (spec 08 v2): a header with
/// the counts, the chips active / ended / archived, then one hairline row per
/// budget. Open = one call; a chip or the sort = one call; a transaction
/// write marks it stale (one reload).
class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({super.key});

  @override
  State<BudgetsListPage> createState() => _BudgetsListPageState();
}

class _BudgetsListPageState extends State<BudgetsListPage> {
  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('budgets');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BudgetsCubit>().load();
    });
  }

  /// A budget page / the create page returns: the list may have changed.
  Future<void> _open(Future<Object?> Function() push) async {
    await push();
    if (mounted) context.read<BudgetsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocListener<TransactionsCubit, TransactionsState>(
          // A write bumps revision; a book-wide refresh (pending submit, debt
          // settle, + sheet) only swaps the rows.
          listenWhen: (a, b) =>
              a.revision != b.revision ||
              !identical(a.transactions, b.transactions),
          listener: (c, _) => c.read<BudgetsCubit>().markStale(),
          child: BlocBuilder<BudgetsCubit, BudgetsState>(
            builder: (context, state) => _body(context, l, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, BudgetsState state) {
    final cubit = context.read<BudgetsCubit>();
    final s = state.summary;
    final active = state.filter == BudgetFilter.active;
    final rows = state.visible;
    final searching = state.query.trim().isNotEmpty;
    final toggleButton = ToolbarToggleButton(
      state: _toolbar,
      // A search text, or another status / sort than the default.
      filtered:
          searching ||
          state.filter != BudgetFilter.active ||
          state.sort != BudgetSort.risk,
      tooltip: l.bgSearchHint,
    );
    return ListPageBody(
      // Only the FIRST load shows the skeleton: a reload keeps the rows.
      loading:
          (state.status == BudgetsStatus.initial ||
              state.status == BudgetsStatus.loading) &&
          state.budgets.isEmpty,
      error: state.budgets.isEmpty ? state.error : null,
      isEmpty: rows.isEmpty,
      onRetry: cubit.load,
      rowDividers: true,
      topInset: AppSpacing.sm,
      rowDividerIndent: 72,
      header: [
        if (active && s.activeCount > 0)
          BudgetSummaryCard(
            summary: s,
            health: state.health,
            onHealth: cubit.setHealth,
            action: toggleButton,
          )
        else
          BudgetCompactCard(
            label: switch (state.filter) {
              BudgetFilter.active => l.bgFilterActive,
              BudgetFilter.ended => '${l.bgFilterEnded} · ${s.endedCount}',
              BudgetFilter.archived =>
                '${l.bgFilterArchived} · ${s.archivedCount}',
            },
            action: toggleButton,
          ),
        ListToolbar(
          collapse: _toolbar,
          searchController: _search,
          onSearchChanged: cubit.search,
          searchHint: l.bgSearchHint,
          chips: [
            OptionMenuAnchor<BudgetFilter>(
              selected: state.filter,
              options: [
                for (final f in BudgetFilter.values)
                  SheetOption(value: f, label: _statusLabel(l, f)),
              ],
              onSelected: cubit.setFilter,
              builder: (context, toggle) => AppChip(
                label:
                    '${l.bgStatusFieldLabel}: ${_statusLabel(l, state.filter)}',
                selected: !active,
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
            ),
          ],
          trailing: OptionMenuAnchor<BudgetSort>(
            selected: state.sort,
            options: [
              for (final o in BudgetSort.values)
                SheetOption(value: o, label: _sortLabel(l, o)),
            ],
            onSelected: cubit.setSort,
            builder: (context, toggle) => AppChip(
              label: l.bgSortChip(_sortLabel(l, state.sort)),
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          ),
        ),
      ],
      empty: searching
          ? EmptyView.compact(message: l.bgNoMatch)
          : EmptyView(
              icon: AppIcons.budget,
              title: switch (state.filter) {
                BudgetFilter.active => l.budgetsEmptyTitle,
                BudgetFilter.ended => l.bgListEmptyEnded,
                BudgetFilter.archived => l.bgListEmptyArchived,
              },
              message: active ? l.budgetsEmptyMessage : '',
              cta: active
                  ? AddTile(
                      label: l.budgetsAddNew,
                      onTap: () =>
                          _open(() => context.push<Object?>('/budgets/new')),
                    )
                  : null,
            ),
      children: [
        for (final b in rows) _row(context, l, b),
        if (active)
          AddTile(
            label: l.budgetsAddNew,
            onTap: () => _open(() => context.push<Object?>('/budgets/new')),
          ),
      ],
    );
  }

  static String _statusLabel(AppLocalizations l, BudgetFilter f) => switch (f) {
    BudgetFilter.active => l.bgFilterActive,
    BudgetFilter.ended => l.bgFilterEnded,
    BudgetFilter.archived => l.bgFilterArchived,
  };

  static String _sortLabel(AppLocalizations l, BudgetSort s) => switch (s) {
    BudgetSort.risk => l.bgSortRisk,
    BudgetSort.alphabetical => l.bgSortName,
    BudgetSort.newest => l.bgSortNewest,
  };

  Widget _row(BuildContext context, AppLocalizations l, Budget b) {
    final x = b.period;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final small = Theme.of(context).textTheme.bodySmall;
    final over = x.overBy > 0;
    final status = x.status == BudgetStatus.pace
        ? null
        : budgetStatusChip(l, b, size: ChipSize.mini);
    final pace =
        b.state == BudgetState.active &&
        (x.onPaceToExceed || x.status == BudgetStatus.pace);
    return ProgressCard(
      title: b.name,
      iconCode: b.iconCode,
      fallbackIcon: AppIcons.budget,
      caption: budgetRowCaption(context, l, b),
      alignWithTitle: true,
      badge: status == null && !pace
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?status,
                if (status != null && pace) const SizedBox(width: 4),
                if (pace)
                  StatusChip.tone(
                    label: l.bgStatusPace,
                    tone: AppChipTone.warning,
                    size: ChipSize.mini,
                  ),
              ],
            ),
      trailing: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${over ? l.bgRowOverAmount : l.bgRowLeft} ',
              style: small?.copyWith(
                color: over ? palette.error : scheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: budgetRowMoney(context, over ? x.overBy : x.remaining),
              style: small?.copyWith(
                fontWeight: FontWeight.w700,
                color: over ? palette.error : scheme.onSurface,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
      value: x.usedRatio,
      expected: x.expected > 0 ? x.expectedRatio : null,
      tone: budgetRowTone(x),
      paceMarker: budgetPaceFraction(x.start, x.end, DateTime.now()),
      label: l.bgRowUsed(
        budgetRowMoney(context, x.used),
        budgetRowMoney(context, x.amount),
      ),
      percentText: '${x.pct}%',
      dimmed: b.state == BudgetState.archived || b.state == BudgetState.ended,
      onTap: () => _open(() => context.push<Object?>('/budgets/${b.id}')),
    );
  }
}
