import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
import '../../domain/budget.dart';
import '../budget_labels.dart';
import '../cubit/budgets_cubit.dart';

class BudgetsListPage extends StatefulWidget {
  const BudgetsListPage({super.key});

  @override
  State<BudgetsListPage> createState() => _BudgetsListPageState();
}

class _BudgetsListPageState extends State<BudgetsListPage> {
  final _search = TextEditingController();
  final _toolbar = AppListToolbarState.of('budgets');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BudgetsCubit>().load();
    });
  }

  /// The status / health / sort remembered on the account, set before the
  /// first load.
  void _restorePrefs() {
    final pref = readPagePref(context, PagePrefIds.budgets);
    final fields = pagePrefPage(PagePrefIds.budgets).fields;
    String pick(String key) =>
        fields.firstWhere((f) => f.key == key).pick(pref);
    context.read<BudgetsCubit>().applyPrefs(
      filter:
          BudgetFilter.values.asNameMap()[pick('filter')] ??
          BudgetFilter.active,
      health:
          BudgetHealth.values.asNameMap()[pick('health')] ?? BudgetHealth.all,
      sort: BudgetSort.values.asNameMap()[pick('sort')] ?? BudgetSort.risk,
    );
  }

  /// Runs a user [change] on the cubit, then remembers the resulting choices
  /// (a status change also resets health; a health tap may toggle back).
  void _change(Future<void> Function(BudgetsCubit cubit) change) {
    final cubit = context.read<BudgetsCubit>();
    unawaited(change(cubit));
    final s = cubit.state;
    unawaited(
      rememberPagePref(context, PagePrefIds.budgets, {
        'filter': s.filter.name,
        'health': s.health.name,
        'sort': s.sort.name,
      }),
    );
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
    final active = state.filter == BudgetFilter.active;
    final rows = state.visible;
    final searching = state.query.trim().isNotEmpty;
    final toggleButton = AppListToolbarToggle(
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
      // No active budgets is not a bare empty screen: the page keeps its
      // summary (zeros), toolbar and the add tile, like saving goals.
      isEmpty: rows.isEmpty && !(active && !searching),
      onRetry: cubit.load,
      rowCards: true,
      topInset: AppSpacing.sm,
      header: [
        if (active)
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
        AppListToolbar(
          state: _toolbar,
          search: ListToolbarSearch(
            controller: _search,
            onChanged: cubit.search,
            hint: l.bgSearchHint,
          ),
          filters: [
            OptionMenuAnchor<BudgetFilter>(
              selected: state.filter,
              options: [
                for (final f in BudgetFilter.values)
                  SheetOption(value: f, label: _statusLabel(l, f)),
              ],
              onSelected: (f) => _change((c) => c.setFilter(f)),
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
            onSelected: (o) => _change((c) => c.setSort(o)),
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
      onTap: () => _change((c) => c.setHealth(h)),
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
          if (s.activeCount > 0) _summaryChip(context, l, state, overBy),
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
    final paceFraction = budgetPaceFraction(x.start, x.end, DateTime.now());
    return ProgressCard(
      title: b.name,
      iconCode: b.iconCode,
      fallbackIcon: AppIcons.budget,
      caption: budgetRowCaption(context, l, b),
      badge: budgetStatusChip(l, b, size: ChipSize.mini),
      trailing: ProgressRemainder(
        label: over ? l.bgRowOverAmount : l.bgRowLeft,
        amount: budgetRowMoney(context, over ? x.overBy : x.remaining),
        over: over,
      ),
      value: x.usedRatio,
      expected: x.expected > 0 ? x.expectedRatio : null,
      expectedLabel: x.expected > 0
          ? '${l.bgFactPending} ${budgetRowMoney(context, x.expected)}'
          : null,
      // The budget's own colour; its status is the chip under the bar.
      tone: ProgressTone.neutral,
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
