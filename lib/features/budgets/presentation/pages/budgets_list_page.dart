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
import '../cubit/budgets_cubit.dart';

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
      filtered:
          searching ||
          state.filter != BudgetFilter.active ||
          state.sort != BudgetSort.risk,
      tooltip: l.bgSearchHint,
    );
    return ListPageBody(
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
          _summary(context, l, state, toggleButton)
        else
          ListSummaryCard(
            caption: switch (state.filter) {
              BudgetFilter.active => l.bgFilterActive,
              BudgetFilter.ended => '${l.bgFilterEnded} · ${s.endedCount}',
              BudgetFilter.archived =>
                '${l.bgFilterArchived} · ${s.archivedCount}',
            },
            style: HeroStyle.tinted(
              color: Theme.of(context).colorScheme.primary,
            ),
            actions: [toggleButton],
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

  Widget _summary(
    BuildContext context,
    AppLocalizations l,
    BudgetsState state,
    Widget toggleButton,
  ) {
    final s = state.summary;
    final cubit = context.read<BudgetsCubit>();
    SummaryTile tile(
      BudgetHealth h,
      String label,
      int count,
      SummaryTileTone tone,
    ) => SummaryTile(
      label: label,
      value: '$count',
      tone: tone,
      selected: state.health == h,
      onTap: () => cubit.setHealth(h),
    );
    return ListSummaryCard(
      caption: l.bgSummaryUsedCaption,
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      actions: [toggleButton],
      amount: s.totalUsed,
      mainSuffix: l.bgHeroOfLimit(budgetRowMoney(context, s.totalLimit)),
      bar: ProgressRow(
        value: s.totalLimit <= 0 ? 0.0 : s.totalUsed / s.totalLimit,
        color: ProgressTone.normal.resolve(context),
        label: l.bgSummaryRemaining(budgetRowMoney(context, s.totalRemaining)),
        trailing: '${s.usedPct}%',
      ),
      tiles: [
        tile(
          BudgetHealth.all,
          l.bgTileAll,
          s.countAll,
          SummaryTileTone.neutral,
        ),
        tile(BudgetHealth.normal, l.bgTileOk, s.countOk, SummaryTileTone.green),
        tile(
          BudgetHealth.near,
          l.bgStatWarn,
          s.countNear,
          SummaryTileTone.amber,
        ),
        tile(BudgetHealth.over, l.bgStatOver, s.countOver, SummaryTileTone.red),
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
          : ProgressBadges(
              children: [
                ?status,
                if (pace)
                  StatusChip.tone(
                    label: l.bgStatusPace,
                    tone: AppChipTone.warning,
                    size: ChipSize.mini,
                  ),
              ],
            ),
      trailing: ProgressRemainder(
        label: over ? l.bgRowOverAmount : l.bgRowLeft,
        amount: budgetRowMoney(context, over ? x.overBy : x.remaining),
        over: over,
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
