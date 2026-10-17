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

/// `/saving-goals` (reference §2, owner 2026-10-17):
///
///   summary card: all savings now · "เดือนนี้ขาดอีก ฿x" · "🐷 ยังไม่จัดสรร ฿x ›"
///   hidden search row: [สถานะ: กำลังออม ▾]
///   เดือนนี้ยังขาด · rows ("ขาด ฿x")   /   เดือนนี้ครบแล้ว ✓ · rows
///   dashed "+ เพิ่มเป้าหมาย"
///
/// Open = ONE call (`GET /saving-goals?status=`); the status chip re-opens it
/// and pull-to-refresh / show-again reload it. Every number is the BE's;
/// adding a saving is the shell's bottom + (ออม mode).
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
            // A failed reload keeps the rows on screen and says so.
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
                // Full-width children: the card and the rows pad themselves.
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
  ) {
    final s = state.overview.summary;
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    return ListSummaryCard(
      caption: l.fpGoalsListCaption,
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      actions: [
        ToolbarToggleButton(
          state: _toolbar,
          filtered:
              _query.isNotEmpty || state.filter != SavingGoalsFilter.active,
          tooltip: l.commonSearch,
        ),
      ],
      amount: s.savedTotal,
      symbol: symbol,
      alert: s.monthShortTotal > 0
          ? l.fpGoalsMonthShortLine(money(s.monthShortTotal))
          : null,
      infoLine: AppText(
        l.fpGoalsSpareLine(money(s.unallocated)),
        role: AppTextRole.caption,
      ),
      onInfoTap: () => context.push('/saving-goals/spare'),
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
    final goals = [
      for (final g in state.goals)
        if (q.isEmpty || g.name.toLowerCase().contains(q)) g,
    ];
    // The BE's order, split by what it says about this month.
    final short = [
      for (final g in goals)
        if ((g.monthShort ?? 0) > 0) g,
    ];
    final done = [
      for (final g in goals)
        if (g.monthShort == 0 || (g.monthShort == null && _isDone(g))) g,
    ];
    final noPlan = [
      for (final g in goals)
        if (!short.contains(g) && !done.contains(g)) g,
    ];
    return [
      _summary(context, l, state),
      _toolbarRow(l, state, cubit),
      if (goals.isEmpty && (!active || _query.isNotEmpty))
        EmptyView.compact(message: l.sgv2EmptyFilteredTitle),
      if (active) ...[
        ..._group(context, l, l.fpGoalsGroupShort, short, _Group.short),
        ..._group(context, l, l.fpGoalsGroupDone, done, _Group.done),
        ..._group(context, l, l.fpGoalsGroupNoPlan, noPlan, _Group.noPlan),
      ] else
        for (final g in goals) _row(context, l, g, _Group.noPlan),
      if (active)
        AddTile(label: l.savingGoalsAddNew, onTap: _add, inList: true),
    ];
  }

  /// A goal with no month figure that has nothing left to do this month.
  static bool _isDone(SavingGoal g) =>
      g.status == SavingStatus.reached || g.isCompleted;

  List<Widget> _group(
    BuildContext context,
    AppLocalizations l,
    String title,
    List<SavingGoal> goals,
    _Group group,
  ) {
    if (goals.isEmpty) return const [];
    return [
      SectionHeader(title: title, count: goals.length),
      for (final g in goals) _row(context, l, g, group),
    ];
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    SavingGoal g,
    _Group group,
  ) {
    final symbol = context.readUserCurrencySymbol;
    String money(double v) => moneyString(context, v, symbol: symbol);
    final badge = savingGoalEtaBadge(context, l, g);
    return SavingGoalRow(
      key: ValueKey(g.id),
      title: g.name,
      iconCode: g.iconCode,
      fallbackIcon: AppIcons.savingGoal,
      value: g.progressPct / 100,
      amountText: '${money(g.savedAmount)} / ${money(g.targetAmount)}',
      trailing: switch (group) {
        _Group.short => l.fpGoalsRowShort(money(g.monthShort ?? 0)),
        _Group.done => '✓',
        _Group.noPlan => null,
      },
      trailingTone: group == _Group.short ? Tone.warning : Tone.success,
      badge: badge?.label,
      badgeTone: badge?.tone ?? Tone.success,
      dimmed: g.isArchived,
      onTap: () => context.push('/saving-goals/${g.id}'),
    );
  }
}

enum _Group { short, done, noPlan }
