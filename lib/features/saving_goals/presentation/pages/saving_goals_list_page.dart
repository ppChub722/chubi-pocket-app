import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
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

  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('saving_goals');

  /// The API has no search param: the loaded goals are filtered by name here.
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
        child: MultiBlocListener(
          listeners: [
            // A transaction write or a saving made elsewhere: reload once.
            BlocListener<TransactionsCubit, TransactionsState>(
              listenWhen: (a, b) =>
                  a.revision != b.revision ||
                  !identical(a.transactions, b.transactions),
              listener: (c, _) => c.read<SavingGoalsCubit>().load(),
            ),
            BlocListener<SavingGoalsCubit, SavingGoalsState>(
              listenWhen: (a, b) => a.staleTick != b.staleTick,
              listener: (c, _) => c.read<SavingGoalsCubit>().load(),
            ),
          ],
          child: BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
            builder: (context, state) {
              final cubit = context.read<SavingGoalsCubit>();
              final active = state.filter == SavingGoalsFilter.active;
              final summary = state.overview.summary;
              final symbol = context.readUserCurrencySymbol;
              final q = _query.toLowerCase();
              final goals = q.isEmpty
                  ? state.goals
                  : [
                      for (final g in state.goals)
                        if (g.name.toLowerCase().contains(q)) g,
                    ];
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
                rowDividers: true,
                rowDividerIndent: 72,
                topInset: AppSpacing.sm,
                header: [
                  AppCard(
                    margin: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.sgv2SavedTotal,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            const MoneyVisibilityToggle(),
                            const SizedBox(width: AppSpacing.xs),
                            ToolbarToggleButton(
                              state: _toolbar,
                              filtered: _query.isNotEmpty || !active,
                              tooltip: l.commonSearch,
                            ),
                          ],
                        ),
                        MoneyText(
                          summary.saved,
                          symbol: symbol,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatGrid(
                          children: [
                            StatTile(
                              caption: l.sgv2InGoals,
                              valueWidget: MoneyText(
                                summary.inGoals,
                                symbol: symbol,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            StatTile(
                              caption: l.sgv2Spare,
                              valueWidget: MoneyText(
                                summary.spare,
                                symbol: symbol,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ListToolbar(
                    collapse: _toolbar,
                    searchController: _search,
                    onSearchChanged: (v) => setState(() => _query = v.trim()),
                    searchHint: l.sgv2SearchHint,
                    chips: [
                      OptionMenuAnchor<SavingGoalsFilter>(
                        selected: state.filter,
                        onSelected: cubit.setFilter,
                        options: [
                          for (final f in SavingGoalsFilter.values)
                            SheetOption(value: f, label: _filterLabel(l, f)),
                        ],
                        builder: (context, toggle) => AppChip(
                          label:
                              '${l.contactsStatusLabel}: ${_filterLabel(l, state.filter)}',
                          selected: !active,
                          trailing: AppChipTrailing.dropdown,
                          onTap: toggle,
                        ),
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
                  if (active && _query.isEmpty)
                    ListRow(
                      leading: IconTile(
                        icon: AppIcons.savingGoal,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                      title: l.sgv2Spare,
                      subtitle: l.sgv2SpareHint,
                      trailing: MoneyText(
                        state.overview.spare.amount,
                        symbol: symbol,
                      ),
                      onTap: () => context.push('/saving-goals/spare'),
                    ),
                  for (final g in goals) _goalRow(context, l, g),
                  if (goals.isEmpty && (!active || _query.isNotEmpty))
                    EmptyView.compact(message: l.sgv2EmptyFilteredTitle),
                  if (active) AddTile(label: l.savingGoalsAddNew, onTap: _add),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _goalRow(BuildContext context, AppLocalizations l, SavingGoal g) {
    final symbol = context.readUserCurrencySymbol;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = g.iconCode.tintFor(palette);
    final tone = g.isCompleted || g.pace == SavingPace.reached
        ? ProgressTone.success
        : (g.isArchived ? ProgressTone.muted : ProgressTone.neutral);
    final badge = savingGoalStatusChip(l, g);
    final paceLine = savingGoalPaceLine(l, g, symbol);
    return ListRow(
      key: ValueKey(g.id),
      dimmed: g.isArchived,
      onTap: () => context.push('/saving-goals/${g.id}'),
      leading: IconCodeWidget(
        iconCode: g.iconCode,
        size: 40,
        displayMode: IconDisplayMode.compact,
        fallbackIcon: AppIcons.savingGoal,
        fallbackColor: tint,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  g.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpacing.sm),
                badge,
              ],
            ],
          ),
          Text(
            savingGoalDueLine(context, l, g, symbol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          ProgressRow(
            value: g.progressPct / 100,
            color: tone.resolve(context, entityTint: tint),
            label: paceLine,
            trailing: '${g.progressPct.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }
}
