import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../domain/budget.dart';
import '../budget_labels.dart';
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
          listenWhen: (a, b) => a.revision != b.revision,
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
    return ListPageBody(
      // Only the FIRST load shows the skeleton: a reload keeps the rows.
      loading:
          (state.status == BudgetsStatus.initial ||
              state.status == BudgetsStatus.loading) &&
          state.budgets.isEmpty,
      error: state.budgets.isEmpty ? state.error : null,
      isEmpty: state.budgets.isEmpty,
      onRetry: cubit.load,
      rowDividers: true,
      header: [
        ListToolbar(
          chips: [
            for (final f in BudgetFilter.values)
              AppChip(
                label: switch (f) {
                  BudgetFilter.active => l.bgFilterActive,
                  BudgetFilter.ended => l.bgFilterEnded,
                  BudgetFilter.archived => l.bgFilterArchived,
                },
                count: switch (f) {
                  BudgetFilter.active => s.activeCount,
                  BudgetFilter.ended => s.endedCount,
                  BudgetFilter.archived => s.archivedCount,
                },
                selected: state.filter == f,
                onTap: () => cubit.setFilter(f),
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
        if (active && s.activeCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: StatGrid(
              children: [
                StatTile(caption: l.bgStatActive, value: '${s.activeCount}'),
                StatTile(
                  caption: l.bgStatOver,
                  value: '${s.overCount}',
                  tone: s.overCount > 0 ? Tone.danger : Tone.neutral,
                ),
                StatTile(
                  caption: l.bgStatWarn,
                  value: '${s.warnCount}',
                  tone: s.warnCount > 0 ? Tone.warning : Tone.neutral,
                ),
                StatTile(
                  caption: l.bgStatPace,
                  value: '${s.paceCount}',
                  tone: s.paceCount > 0 ? Tone.warning : Tone.neutral,
                ),
              ],
            ),
          ),
      ],
      empty: EmptyView(
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
                onTap: () => _open(() => context.push<Object?>('/budgets/new')),
              )
            : null,
      ),
      children: [
        for (final b in state.budgets) _row(context, l, b),
        if (active)
          AddTile(
            label: l.budgetsAddNew,
            onTap: () => _open(() => context.push<Object?>('/budgets/new')),
          ),
      ],
    );
  }

  static String _sortLabel(AppLocalizations l, BudgetSort s) => switch (s) {
    BudgetSort.risk => l.bgSortRisk,
    BudgetSort.alphabetical => l.bgSortName,
    BudgetSort.newest => l.bgSortNewest,
  };

  Widget _row(BuildContext context, AppLocalizations l, Budget b) {
    final x = b.period;
    final caption = [
      if (b.recurring && b.rule != null) '🔁 ${budgetRuleLabel(l, b.rule!)}',
      budgetRange(context, x.start, x.end),
      if (x.daysLeft != null && b.state == BudgetState.active)
        l.bgRowDaysLeft(x.daysLeft!),
    ].join(' · ');
    return ProgressCard(
      title: b.name,
      iconCode: b.iconCode,
      fallbackIcon: AppIcons.budget,
      caption: caption,
      badge: budgetStatusChip(l, b, size: ChipSize.mini),
      value: x.usedRatio,
      expected: x.expected > 0 ? x.expectedRatio : null,
      tone: budgetProgressTone(x),
      label: [
        l.bgRowUsed(
          moneyString(context, x.used),
          moneyString(context, x.amount),
        ),
        if (x.expected > 0) l.bgRowExpected(moneyString(context, x.expected)),
      ].join(' · '),
      overLabel: x.overBy > 0
          ? l.bgRowOverBy(moneyString(context, x.overBy))
          : null,
      percentText: '${x.pct}%',
      dimmed: b.state == BudgetState.archived || b.state == BudgetState.ended,
      onTap: () => _open(() => context.push<Object?>('/budgets/${b.id}')),
    );
  }
}
