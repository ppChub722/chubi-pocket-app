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
import '../../domain/saving_goal_plan.dart';
import '../cubit/saving_goals_cubit.dart';
import '../widgets/saving_goal_texts.dart';

class SavingGoalsListPage extends StatefulWidget {
  const SavingGoalsListPage({super.key});

  @override
  State<SavingGoalsListPage> createState() => _SavingGoalsListPageState();
}

class _SavingGoalsListPageState extends State<SavingGoalsListPage> {
  late final SavingGoalsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SavingGoalsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cubit.loadIfNeeded();
    });
  }

  final _search = TextEditingController();
  final _toolbar = ToolbarToggleState.of('saving_goals');

  String _query = '';
  _GoalChip _chip = _GoalChip.all;

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
            BlocListener<TransactionsCubit, TransactionsState>(
              listenWhen: (a, b) =>
                  a.revision != b.revision ||
                  !identical(a.transactions, b.transactions),
              listener: (c, _) => c.read<SavingGoalsCubit>().load(),
            ),
            BlocListener<SavingGoalsCubit, SavingGoalsState>(
              listenWhen: (a, b) =>
                  a.status != b.status &&
                  b.status == SavingGoalsStatus.error &&
                  b.overview.summary.currency.isNotEmpty,
              listener: (c, _) =>
                  showAppSnackBar(c, l.fpGoalsRefreshFailed, tone: Tone.danger),
            ),
          ],
          child: BlocBuilder<SavingGoalsCubit, SavingGoalsState>(
            builder: (context, state) {
              final cubit = context.read<SavingGoalsCubit>();
              // The BE always sends the user currency: empty = never loaded.
              final neverLoaded = state.overview.summary.currency.isEmpty;
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
                empty: EmptyView(
                  icon: AppIcons.savingGoal,
                  title: l.savingGoalsEmptyTitle,
                  message: l.savingGoalsEmptyMessage,
                ),
                sidePadding: 0,
                topInset: 0,
                children: _children(context, l, state, cubit),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    AppLocalizations l,
    SavingGoalsState state,
    List<SavingGoal> all,
  ) {
    final s = state.overview.summary;
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    // Long-term progress (owner 2026-10-21): the targets, not this month.
    final target = s.targetTotal;
    final targetShort = s.targetShortTotal;
    HeroFilter filter(
      _GoalChip chip,
      String label,
      int count, {
      AppChipTone? tone,
    }) => HeroFilter(
      label: label,
      count: count,
      tone: tone,
      selected: _chip == chip,
      onTap: () => setState(() => _chip = chip),
    );
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      header: HeroSummaryHead(
        icon: AppIcons.savings,
        label: l.fpGoalsFactTotal,
        amount: MoneyText(s.savedTotal, symbol: symbol),
        actions: [
          ToolbarToggleButton(
            state: _toolbar,
            filtered:
                _query.isNotEmpty ||
                state.filter != SavingGoalsFilter.active ||
                state.sort != SavingGoalsSort.needFirst,
            tooltip: l.commonSearch,
          ),
        ],
      ),
      content: [
        Builder(
          builder: (context) => HeroRingRow(
            ring: (size) => HeroRing(
              size: size,
              stroke: 14,
              value: s.targetPercent / 100,
              label: l.fpGoalsSavedLabel,
              amount: MoneyText(s.targetSavedTotal, symbol: symbol),
              target: target > 0 ? l.fpGoalsRingOfPlan(money(target)) : null,
            ),
            facts: [
              HeroFact(
                l.fpGoalsFactTargetShort,
                money(targetShort),
                color: targetShort > 0
                    ? HeroColors.maybeOf(context)?.warning
                    : null,
                icon: AppIcons.savingGoal,
              ),
              HeroFact(
                l.fpGoalsFactMonthToSave,
                money(s.monthShortTotal),
                icon: AppIcons.date,
              ),
              HeroFact(
                l.sgv2Spare,
                money(s.unallocated),
                icon: AppIcons.wallet,
                onTap: () => context.push('/saving-goals/spare'),
              ),
              HeroFact(
                l.fpGoalsFactGoals,
                '${all.length}',
                icon: AppIcons.target,
              ),
            ],
          ),
        ),
      ],
      footer: [
        // Long-term counts from the BE (has a target and not reached ·
        // reached or closed · no target).
        HeroFilterChips(
          filters: [
            filter(_GoalChip.all, l.fpGoalsFilterAll, all.length),
            filter(
              _GoalChip.short,
              l.fpGoalsFilterShort,
              s.countShort,
              tone: AppChipTone.warning,
            ),
            filter(
              _GoalChip.done,
              l.fpGoalsReached,
              s.countDone,
              tone: AppChipTone.success,
            ),
            filter(_GoalChip.free, l.fpGoalsFilterFree, s.countNoTarget),
          ],
        ),
      ],
    );
  }

  Widget _toolbarRow(
    AppLocalizations l,
    SavingGoalsState state,
    SavingGoalsCubit cubit,
  ) {
    return ListToolbar(
      collapse: _toolbar,
      searchController: _search,
      onSearchChanged: (v) => setState(() => _query = v.trim()),
      searchHint: l.sgv2SearchHint,
      trailing: SortChip<SavingGoalsSort>(
        value: state.sort,
        tooltip: l.fpM5GoalsSortTooltip,
        options: [
          SortOption(SavingGoalsSort.needFirst, l.fpGoalsSortNeed),
          SortOption(SavingGoalsSort.created, l.fpM5GoalsSortCreated),
          SortOption(SavingGoalsSort.deadline, l.fpM5GoalsSortDeadline),
          SortOption(SavingGoalsSort.progress, l.fpM5GoalsSortProgress),
          SortOption(SavingGoalsSort.remaining, l.fpM5GoalsSortRemaining),
          SortOption(SavingGoalsSort.byName, l.fpM5GoalsSortName),
        ],
        onChanged: cubit.setSort,
      ),
      chips: [
        OptionMenuAnchor<SavingGoalsFilter>(
          selected: state.filter,
          onSelected: cubit.setFilter,
          options: [
            for (final f in SavingGoalsFilter.values)
              SheetOption(value: f, label: _filterLabel(l, f)),
          ],
          builder: (context, toggle) => AppChip(
            label: l.fpGoalsStatusChip(_filterLabel(l, state.filter)),
            selected: state.filter != SavingGoalsFilter.active,
            trailing: AppChipTrailing.dropdown,
            onTap: toggle,
          ),
        ),
      ],
    );
  }

  List<Widget> _children(
    BuildContext context,
    AppLocalizations l,
    SavingGoalsState state,
    SavingGoalsCubit cubit,
  ) {
    final active = state.filter == SavingGoalsFilter.active;
    final q = _query.toLowerCase();
    final all = state.goals;
    final goals = [
      for (final g in all)
        if ((q.isEmpty || g.name.toLowerCase().contains(q)) &&
            _chip.matches(SavingGoalProgress.of(g)))
          g,
    ];
    return [
      _summary(context, l, state, all),
      _toolbarRow(l, state, cubit),
      if (goals.isEmpty &&
          (!active || _query.isNotEmpty || _chip != _GoalChip.all))
        EmptyView.compact(message: l.sgv2EmptyFilteredTitle),
      if (goals.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            0,
          ),
          child: SectionCard(
            first: true,
            children: [for (final g in goals) _row(context, l, g)],
          ),
        ),
      if (active)
        AddTile(label: l.savingGoalsAddNew, onTap: _add, inList: true),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations l, SavingGoal g) {
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    final palette = Theme.of(context).extension<AppColors>()!;
    final tint = g.iconCode.tintFor(palette);
    final behind =
        !g.isArchived && !g.isCompleted && g.status == SavingStatus.behind;
    final status = g.isArchived
        ? ListRowChip(l.sgv2FilterArchived, tone: Tone.neutral)
        : g.isCompleted
        ? ListRowChip(l.fpGoalsClosed, tone: Tone.success)
        : behind
        ? ListRowChip(l.fpGoalsBehind, tone: Tone.warning)
        : null;
    final target = g.targetAmount;
    final saved = MoneyText(g.savedAmount, symbol: symbol);
    final leading = IconCodeWidget(
      iconCode: g.iconCode,
      size: 36,
      displayMode: IconDisplayMode.compact,
      fallbackIcon: AppIcons.savingGoal,
      fallbackColor: tint,
    );
    if (target == null) {
      return AppListRow(
        key: ValueKey(g.id),
        leading: leading,
        title: g.name,
        status: status,
        line2: ListRowLine(parts: [l.fpGoalsGroupOngoing]),
        trailing: ListRowTrailing.value(
          saved,
          caption: l.fpGoalsRowMonthOnly(
            l.fpGoalsThisMonth,
            signedMoneyString(
              context,
              g.monthSaved,
              negative: g.monthSaved < 0,
              symbol: symbol,
            ),
          ),
        ),
        dimmed: g.isArchived,
        onTap: () => context.push('/saving-goals/${g.id}'),
      );
    }
    final pct = (g.progressPct ?? 0).round();
    final left = g.remainingAmount ?? target - g.savedAmount;
    final goal = l.sgv2ChartTarget(money(target));
    final due = savingGoalDueCaption(context, l, g);
    return AppListRow(
      key: ValueKey(g.id),
      leading: leading,
      title: g.name,
      status: status,
      line2: due == null ? null : ListRowLine(parts: [due]),
      trailing: left <= 0
          ? ListRowTrailing.text(
              l.fpGoalsRowDone,
              tone: Tone.success,
              caption: goal,
            )
          : ListRowTrailing.value(saved, caption: goal),
      footer: ProgressRow(
        value: (g.progressPct ?? 0) / 100,
        color: behind ? Tone.warning.color(context) : tint,
        fillLabel: '$pct%',
      ),
      dimmed: g.isArchived,
      onTap: () => context.push('/saving-goals/${g.id}'),
    );
  }
}

enum _GoalChip {
  all,
  short,
  done,
  free;

  /// Long-term, like the BE counts on the chips.
  bool matches(SavingGoalProgress p) => switch (this) {
    all => true,
    short => p == SavingGoalProgress.short,
    done => p == SavingGoalProgress.done,
    free => p == SavingGoalProgress.noTarget,
  };
}
