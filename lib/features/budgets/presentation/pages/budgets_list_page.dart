import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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

  /// Back from a budget page: reload only if it wrote something.
  Future<void> _open(Future<Object?> Function() push) async {
    await push();
    if (!mounted) return;
    final cubit = context.read<BudgetsCubit>();
    if (cubit.takeStale()) cubit.load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.budgetsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<BudgetsCubit, BudgetsState>(
          builder: (context, state) => _body(context, l, state),
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
      rowCards: true,
      topInset: AppSpacing.sm,
      header: [
        if (active && s.activeCount > 0)
          _summary(context, l, state, toggleButton)
        else
          AppHeroCard(
            style: HeroStyle.tinted(
              color: Theme.of(context).colorScheme.primary,
            ),
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            header: HeroHeader(
              leading: [HeroModuleTile(AppIcons.budget)],
              actions: [toggleButton],
            ),
            content: const [],
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
      footer: active
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: AddTile(
                label: l.budgetsAddNew,
                onTap: () => _open(() => context.push<Object?>('/budgets/new')),
              ),
            )
          : null,
      children: [for (final b in rows) _row(context, l, b)],
    );
  }

  /// Total used against the plan to date of the budgets that have a plan (one
  /// with no end date has none); over the total limit ([overBy] > 0) it reads
  /// "over".
  Widget _summaryChip(
    BuildContext context,
    AppLocalizations l,
    BudgetsState state,
    double overBy,
  ) {
    if (overBy > 0) {
      return StatusChip(
        label: l.bgStatusOverBy(budgetRowMoney(context, overBy)),
        kind: StatusKind.over,
        emphasis: true,
      );
    }
    final now = DateTime.now();
    var plan = 0.0;
    var used = 0.0;
    for (final b in state.budgets) {
      if (b.state != BudgetState.active) continue;
      final x = b.period;
      final pace = budgetPaceFraction(x.start, x.end, now);
      if (pace == null) continue;
      plan += x.amount * pace;
      used += x.used;
    }
    if (used > plan) {
      return StatusChip(
        label: l.bgStatusAhead(budgetRowMoney(context, used - plan)),
        kind: StatusKind.warning,
        emphasis: true,
      );
    }
    return StatusChip.tone(
      label: l.bgStatusOnPlan,
      tone: AppChipTone.primary,
      emphasis: true,
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
    final overBy = s.totalRemaining < 0 ? -s.totalRemaining : 0.0;
    final over = overBy > 0;
    HeroFilter filter(
      BudgetHealth h,
      String label,
      int count, [
      AppChipTone? tone,
    ]) => HeroFilter(
      label: label,
      count: count,
      tone: tone,
      selected: state.health == h,
      onTap: () => cubit.setHealth(h),
    );
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      header: HeroHeader(
        leading: [
          HeroModuleTile(AppIcons.budget),
          _summaryChip(context, l, state, overBy),
        ],
        actions: [toggleButton],
      ),
      content: [
        HeroRingRow(
          ring: (size) => HeroRing(
            size: size,
            stroke: 14,
            value: s.totalLimit <= 0 ? 0.0 : s.totalUsed / s.totalLimit,
            color: over
                ? ProgressTone.danger.resolve(
                    context,
                    entityTint: Theme.of(context).colorScheme.primary,
                  )
                : null,
            label: over ? l.fpBudgetsOverLabel : l.bgRingTotalLeft,
            amount: MoneyText(
              over ? overBy : s.totalRemaining,
              symbol: context.readUserCurrencySymbol,
            ),
            target: l.bgRingOf(budgetRowMoney(context, s.totalLimit)),
          ),
          facts: [
            HeroFact(
              l.bgFactUsedTotal,
              budgetRowMoney(context, s.totalUsed),
              icon: AppIcons.receipt,
            ),
            HeroFact(l.bgFactUsedPct, '${s.usedPct}%', icon: AppIcons.pie),
            HeroFact(
              l.bgFactBudgetCount,
              l.bgCountBudgets(s.activeCount),
              icon: AppIcons.layers,
            ),
          ],
        ),
      ],
      footer: [
        HeroFilterChips(
          filters: [
            filter(BudgetHealth.all, l.bgTileAll, s.countAll),
            filter(
              BudgetHealth.normal,
              l.bgTileOk,
              s.countOk,
              AppChipTone.success,
            ),
            filter(
              BudgetHealth.near,
              l.bgStatWarn,
              s.countNear,
              AppChipTone.warning,
            ),
            filter(
              BudgetHealth.over,
              l.bgStatOver,
              s.countOver,
              AppChipTone.danger,
            ),
          ],
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
    final over = x.overBy > 0;
    final status = x.status == BudgetStatus.pace
        ? null
        : budgetStatusChip(l, b, size: ChipSize.mini);
    final pace =
        b.state == BudgetState.active &&
        (x.onPaceToExceed || x.status == BudgetStatus.pace);
    final paceFraction = budgetPaceFraction(x.start, x.end, DateTime.now());
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
      paceMarker: paceFraction,
      paceBubble: paceFraction == null
          ? null
          : l.bgPaceBubble(budgetRowMoney(context, x.amount * paceFraction)),
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
