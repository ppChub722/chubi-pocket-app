import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/saving_goal.dart';
import '../cubit/saving_goals_cubit.dart';
import '../widgets/saving_goal_texts.dart';

/// `/saving-goals` — the savings notebook: total saved / spare in the header,
/// the "ยังไม่จัดสรร" bucket, then one row per goal (progress, deadline, pace).
/// Open = ONE call (`GET /saving-goals?status=`); the chips re-open it.
class SavingGoalsListPage extends StatefulWidget {
  const SavingGoalsListPage({super.key});

  @override
  State<SavingGoalsListPage> createState() => _SavingGoalsListPageState();
}

class _SavingGoalsListPageState extends State<SavingGoalsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SavingGoalsCubit>().loadIfNeeded();
    });
  }

  void _add() => context.push('/saving-goals/new');

  String _filterLabel(AppLocalizations l, SavingGoalsFilter f) => switch (f) {
    SavingGoalsFilter.active => l.sgv2FilterActive,
    SavingGoalsFilter.completed => l.sgv2FilterCompleted,
    SavingGoalsFilter.archived => l.sgv2FilterArchived,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.savingGoalsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
          builder: (context, state) {
            final cubit = context.read<SavingGoalsCubit>();
            final active = state.filter == SavingGoalsFilter.active;
            final summary = state.overview.summary;
            final symbol = Currencies.symbolOf(summary.currency);
            // The BE always sends the user currency: empty = never loaded.
            final neverLoaded = summary.currency.isEmpty;
            return ListPageBody(
              // Only the FIRST load shows the skeleton: a reload keeps the
              // rows (a skeleton would kill a pull-to-refresh).
              loading:
                  (state.status == SavingGoalsStatus.initial ||
                      state.status == SavingGoalsStatus.loading) &&
                  neverLoaded,
              error: state.status == SavingGoalsStatus.error && neverLoaded
                  ? state.error
                  : null,
              isEmpty: neverLoaded,
              onRetry: cubit.load,
              header: [
                SummaryStats(
                  stats: [
                    SummaryStat(label: l.sgv2SavedTotal, amount: summary.saved),
                    SummaryStat(label: l.sgv2InGoals, amount: summary.inGoals),
                    SummaryStat(label: l.sgv2Spare, amount: summary.spare),
                  ],
                ),
                ListToolbar(
                  chips: [
                    for (final f in SavingGoalsFilter.values)
                      AppChip(
                        label: _filterLabel(l, f),
                        selected: state.filter == f,
                        onTap: () => cubit.setFilter(f),
                      ),
                  ],
                ),
              ],
              empty: EmptyView(
                icon: AppIcons.savingGoal,
                title: l.savingGoalsEmptyTitle,
                message: l.savingGoalsEmptyMessage,
              ),
              children: [
                if (active)
                  ListRow(
                    leading: const Icon(AppIcons.savingGoal),
                    title: l.sgv2Spare,
                    subtitle: l.sgv2SpareHint,
                    trailing: MoneyText(
                      state.overview.spare.amount,
                      symbol: symbol,
                    ),
                    onTap: () => context.push('/saving-goals/spare'),
                  ),
                for (final g in state.goals) _goalRow(context, l, g),
                if (!active && state.goals.isEmpty)
                  EmptyView.compact(message: l.sgv2EmptyFilteredTitle),
                if (active) AddTile(label: l.savingGoalsAddNew, onTap: _add),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _goalRow(BuildContext context, AppLocalizations l, SavingGoal g) {
    final symbol = Currencies.symbolOf(g.currency);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ProgressCard(
        title: g.name,
        caption: savingGoalDueLine(context, l, g, symbol),
        iconCode: g.iconCode,
        fallbackIcon: AppIcons.savingGoal,
        badge: savingGoalStatusChip(l, g),
        value: g.progressPct / 100,
        tone: g.isCompleted || g.pace == SavingPace.reached
            ? ProgressTone.success
            : (g.isArchived ? ProgressTone.muted : ProgressTone.neutral),
        label: savingGoalPaceLine(l, g, symbol),
        percentText: '${g.progressPct.toStringAsFixed(0)}%',
        dimmed: g.isArchived,
        onTap: () => context.push('/saving-goals/${g.id}'),
      ),
    );
  }
}
