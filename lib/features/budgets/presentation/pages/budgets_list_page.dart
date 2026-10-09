import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/budget.dart';
import '../../domain/budget_overview.dart';
import '../../domain/budget_period.dart';
import '../cubit/budgets_cubit.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_overview_card.dart';

/// `/budgets` — overview dashboard card on top, then the user-scope budgets
/// as cards (grouped by period when there's more than one) with a dashed
/// "+ เพิ่มงบ" at the end (§1.2 card page — no top-bar add). Project
/// budgets live on the project.
class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({super.key});

  @override
  State<BudgetsListPage> createState() => _BudgetsListPageState();
}

class _BudgetsListPageState extends State<BudgetsListPage> {
  /// The switcher's pick; null = default (monthly, else the first period
  /// the user has).
  BudgetPeriod? _picked;
  BudgetOverview? _overview;

  /// Last overview fetch failed → the card is left out.
  bool _overviewFailed = false;

  /// Drops stale overview responses (period switched / list reloaded).
  int _overviewRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<BudgetsCubit>();
      if (cubit.state.status == BudgetsStatus.loaded) {
        _loadOverview(cubit.state.budgets);
      } else {
        cubit.loadIfNeeded();
      }
    });
  }

  void _add() => context.push('/budgets/new');

  /// Periods the user has budgets in, in enum order.
  static List<BudgetPeriod> _periods(List<Budget> budgets) => [
    for (final p in BudgetPeriod.values)
      if (budgets.any((b) => b.period == p)) p,
  ];

  BudgetPeriod? _period(List<BudgetPeriod> periods) {
    if (periods.isEmpty) return null;
    if (_picked != null && periods.contains(_picked)) return _picked;
    return periods.contains(BudgetPeriod.monthly)
        ? BudgetPeriod.monthly
        : periods.first;
  }

  /// Overview isn't cached by the cubit — refetched whenever the list
  /// (re)loads or changes, and on a period switch.
  Future<void> _loadOverview(List<Budget> budgets) async {
    final period = _period(_periods(budgets));
    final request = ++_overviewRequest;
    if (period == null) {
      setState(() => _overview = null);
      return;
    }
    try {
      final o = await context.read<BudgetsCubit>().overview(period: period);
      if (!mounted || request != _overviewRequest) return;
      setState(() {
        _overview = o;
        _overviewFailed = false;
      });
    } catch (_) {
      // The card is a summary — on failure it's just left out; the list
      // below still works and pull-to-refresh retries.
      if (!mounted || request != _overviewRequest) return;
      setState(() {
        _overview = null;
        _overviewFailed = true;
      });
    }
  }

  void _switchPeriod(BudgetPeriod p, List<Budget> budgets) {
    setState(() {
      _picked = p;
      _overviewFailed = false;
    });
    _loadOverview(budgets);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocConsumer<BudgetsCubit, BudgetsState>(
          listenWhen: (prev, cur) =>
              cur.status == BudgetsStatus.loaded &&
              (prev.status != cur.status || prev.budgets != cur.budgets),
          listener: (context, state) => _loadOverview(state.budgets),
          builder: (context, state) => AsyncStateView(
            loading:
                state.status == BudgetsStatus.initial ||
                state.status == BudgetsStatus.loading,
            error: state.error,
            isEmpty: state.budgets.isEmpty,
            onRetry: context.read<BudgetsCubit>().load,
            skeleton: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                MediaQuery.paddingOf(context).top + AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              children: [
                BudgetOverviewCard(
                  periods: const [],
                  period: BudgetPeriod.monthly,
                  onPeriodChanged: (_) {},
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < 4; i++) const SkeletonListTile(),
              ],
            ),
            empty: EmptyView(
              icon: AppIcons.budget,
              title: l.budgetsEmptyTitle,
              message: l.budgetsEmptyMessage,
              cta: AddTile(label: l.budgetsAddNew, onTap: _add),
            ),
            builder: (context) => _list(context, l, state.budgets),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, AppLocalizations l, List<Budget> all) {
    final periods = _periods(all);
    final period = _period(periods)!;
    final overview = _overview?.period == period ? _overview : null;
    final grouped = periods.length > 1;

    List<Widget> cards(Iterable<Budget> budgets) => [
      for (final b in budgets) ...[
        BudgetCard(budget: b, onTap: () => context.push('/budgets/${b.id}')),
        const SizedBox(height: AppSpacing.md),
      ],
    ];

    return PullToRefresh(
      onRefresh: () => context.read<BudgetsCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Top: clear the floating top bar.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          MediaQuery.paddingOf(context).top + AppSpacing.md,
          AppSpacing.lg,
          96,
        ),
        children: [
          if (!_overviewFailed) ...[
            BudgetOverviewCard(
              periods: periods,
              period: period,
              overview: overview,
              onPeriodChanged: (p) => _switchPeriod(p, all),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (grouped)
            for (final p in periods) ...[
              SectionHeader(
                title: budgetPeriodLabel(l, p),
                count: all.where((b) => b.period == p).length,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                ),
              ),
              ...cards(all.where((b) => b.period == p)),
            ]
          else
            ...cards(all),
          AddTile(label: l.budgetsAddNew, onTap: _add),
        ],
      ),
    );
  }
}
