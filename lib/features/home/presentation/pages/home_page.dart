import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../../../saving_goals/presentation/cubit/saving_goals_cubit.dart';
import '../../../scheduled_transactions/presentation/cubit/scheduled_transactions_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/quick_create_sheet.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/dashboard.dart';
import '../cubit/dashboard_cubit.dart';

/// Dashboard — the whole picture at a glance, one `GET /dashboard`.
///
/// Top to bottom: month picker (👁) → net worth → this month in/out →
/// coming up (subscriptions, installments, card dues; overdue first) →
/// where the money went (donut) → 6-month trend → budgets · debts ·
/// goals tiles → recent. The month picker drives the month-scoped blocks;
/// the rest is "right now".
///
/// Stays fresh on its own: any transaction write or wallet change
/// elsewhere reloads it (plus pull-to-refresh).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // First tab → warms the shared caches other screens lean on;
      // TransactionTile (recent) resolves category icons from here.
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      // App-scoped cubit (the More hub reads it too).
      context.read<DashboardCubit>().loadIfNeeded();
      // Drafts badge (top bar) + the รอยืนยัน block below.
      context.read<PendingCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) => TabRootScaffold(
    title: AppLocalizations.of(context)!.navDashboard,
    body: const _HomeView(),
  );
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionsCubit, TransactionsState>(
          listenWhen: (a, b) => a.revision != b.revision,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        BlocListener<AccountsCubit, AccountsState>(
          listenWhen: (a, b) =>
              b.status == AccountsStatus.loaded && a.accounts != b.accounts,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        // Tiles + "coming up" read these; any change → one reload.
        BlocListener<BudgetsCubit, BudgetsState>(
          listenWhen: (a, b) => a.budgets != b.budgets,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        BlocListener<SavingGoalsCubit, SavingGoalsState>(
          listenWhen: (a, b) => a.goals != b.goals,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        BlocListener<PersonalDebtsCubit, PersonalDebtsState>(
          listenWhen: (a, b) => a.debts != b.debts,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        BlocListener<ScheduledTransactionsCubit, ScheduledTransactionsState>(
          listenWhen: (a, b) => a.entries != b.entries,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();
          return AsyncStateView(
            loading:
                state.status == DashboardStatus.initial ||
                state.status == DashboardStatus.loading,
            error: state.error,
            isEmpty: state.data == null,
            onRetry: cubit.load,
            // Stale data + a failed load → the banner below, not a snackbar.
            snackOnRefreshError: false,
            skeleton: ListView(
              // Body sits under the transparent top bar.
              padding: const EdgeInsets.all(
                AppSpacing.lg,
              ).add(EdgeInsets.only(top: MediaQuery.paddingOf(context).top)),
              children: const [
                SkeletonBox(height: 40),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 110),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 90),
                SizedBox(height: AppSpacing.lg),
                SkeletonBox(height: 120),
                SizedBox(height: AppSpacing.lg),
                SkeletonBox(height: 160),
              ],
            ),
            builder: (context) {
              final d = state.data!;
              return PullToRefresh(
                onRefresh: cubit.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Body sits under the transparent top bar.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    MediaQuery.paddingOf(context).top + AppSpacing.xs,
                    AppSpacing.lg,
                    96,
                  ),
                  children: [
                    _MonthBar(
                      month: d.month,
                      loading: state.status == DashboardStatus.loading,
                    ),
                    if (state.status == DashboardStatus.error) ...[
                      MessageBanner(
                        message: l.homeLoadError,
                        tone: Tone.danger,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _NetWorthCard(netWorth: d.netWorth),
                    const _PendingBlock(),
                    const SizedBox(height: AppSpacing.md),
                    _MonthCard(current: d.summary, previous: d.previous),
                    if (d.upcoming.items.isNotEmpty)
                      _ComingUp(block: d.upcoming),
                    _WhereItWent(d: d),
                    _Trend(points: d.trend),
                    const SizedBox(height: AppSpacing.lg),
                    _Tiles(d: d),
                    _Recent(d: d),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

// ── Month picker ──────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month, required this.loading});

  final DateTime month;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<DashboardCubit>();
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    return Row(
      children: [
        IconButton(
          tooltip: l.homePrevMonth,
          icon: const Icon(AppIcons.chevronLeft),
          onPressed: () => cubit.shiftMonth(-1),
        ),
        Text(
          DateFormat.yMMMM(_locale(context)).format(month),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          tooltip: l.homeNextMonth,
          icon: const Icon(AppIcons.chevronRight),
          onPressed: isCurrent ? null : () => cubit.shiftMonth(1),
        ),
        if (loading)
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const Spacer(),
        const MoneyVisibilityToggle(),
      ],
    );
  }
}

// ── Net worth ─────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.netWorth});

  final NetWorth netWorth;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () => context.go('/accounts'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.homeNetWorthLabel, style: textTheme.labelLarge),
              MoneyText(
                netWorth.total,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text('${l.homeAssets} ', style: muted),
                  MoneyText(netWorth.assets, style: muted),
                  if (netWorth.liabilities > 0) ...[
                    Text('  ·  ${l.homeLiabilities} ', style: muted),
                    MoneyText(netWorth.liabilities, style: muted),
                  ],
                  const Spacer(),
                  Text(
                    l.homeNetWorthAccountCount(netWorth.accountsCount),
                    style: muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── This month ────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.current, required this.previous});

  final PeriodTotals current;
  final PeriodTotals previous;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    // Spending change vs last month — only when there's a base to compare.
    final pct = previous.expense > 0
        ? ((current.expense - previous.expense) / previous.expense * 100)
              .round()
        : null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SummaryStats(
              stats: [
                SummaryStat(
                  label: l.homeIncome,
                  amount: current.income,
                  tone: MoneyTone.income,
                ),
                SummaryStat(
                  label: l.homeExpense,
                  amount: current.expense,
                  tone: MoneyTone.expense,
                ),
                SummaryStat(
                  label: l.homeLeftOver,
                  amount: current.net,
                  tone: MoneyTone.signed,
                ),
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    l.homeVsPrevMonth,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    pct > 0
                        ? AppIcons.trendUp
                        : pct < 0
                        ? AppIcons.trendDown
                        : AppIcons.trendFlat,
                    size: 14,
                    // Spending up = expense colour; down = income colour.
                    color: pct > 0
                        ? palette.expense
                        : pct < 0
                        ? palette.income
                        : scheme.onSurfaceVariant,
                  ),
                  Text(
                    '${pct.abs()}%',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Coming up ─────────────────────────────────────────────────────────

class _ComingUp extends StatelessWidget {
  const _ComingUp({required this.block});

  final UpcomingBlock block;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: l.homeComingUp,
                  padding: EdgeInsets.zero,
                ),
              ),
              Text('${l.homeComingUpWindow(block.days)}  ', style: muted),
              MoneyText(-block.totalExpense, tone: MoneyTone.signed),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: block.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => _UpcomingCard(item: block.items[i]),
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final when = item.overdue
        ? l.homeOverdueDays(-item.daysUntil)
        : item.daysUntil <= 1
        ? l.homeUpcomingInDays(item.daysUntil)
        : DateFormat.MMMd(_locale(context)).format(item.dueDate);
    final isCard = item.kind == UpcomingKind.cardDue;
    return SizedBox(
      width: 112,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: item.overdue
              ? BorderSide(color: palette.expense, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            isCard
                ? '/accounts/${item.id}'
                : '/scheduled-transactions/${item.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: item.overdue
                        ? palette.expense
                        : scheme.onSurfaceVariant,
                    fontWeight: item.overdue ? FontWeight.w700 : null,
                  ),
                ),
                const Spacer(),
                IconDisplay(
                  type: isCard ? IconType.account : IconType.category,
                  size: 28,
                  imageUrl: item.logoUrl,
                  iconCode: item.iconCode,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isCard ? '${l.homeCardDue} ${item.name}' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
                MoneyText(
                  item.amount,
                  tone: item.type == TransactionType.income
                      ? MoneyTone.income
                      : MoneyTone.expense,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Where it went ─────────────────────────────────────────────────────

class _WhereItWent extends StatelessWidget {
  const _WhereItWent({required this.d});

  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = ChartPalette.categorical(context);
    final month = '${d.month.year}-${d.month.month.toString().padLeft(2, '0')}';
    // (label, amount, colour, drill-down query or null for "อื่นๆ")
    final rows = <(String, double, Color, String?)>[
      for (var i = 0; i < d.topCategories.length; i++)
        () {
          final c = d.topCategories[i];
          final label = c.categoryId == null ? l.homeUncategorized : c.name;
          final target = c.categoryId == null
              ? 'uncategorized=true'
              : 'category=${c.categoryId}';
          return (
            label,
            c.expense,
            colors[i % colors.length],
            '$target&month=$month&title=${Uri.encodeQueryComponent(label)}',
          );
        }(),
      if (d.otherExpense > 0)
        (l.homeOther, d.otherExpense, ChartPalette.other(context), null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l.homeWhereMoneyWent,
          actionLabel: l.homeRecentViewAll,
          onAction: () => context.go('/transactions'),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: rows.isEmpty
                ? Text(l.homeNoExpense, style: textTheme.bodyMedium)
                : Row(
                    children: [
                      DonutChart(
                        size: 112,
                        segments: [
                          for (final r in rows)
                            DonutSegment(value: r.$2, color: r.$3),
                        ],
                        center: MoneyText(
                          d.summary.expense,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          children: [
                            for (final r in rows)
                              InkWell(
                                onTap: r.$4 == null
                                    ? null
                                    : () => context.push('/browse?${r.$4}'),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: r.$3,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          r.$1,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodySmall,
                                        ),
                                      ),
                                      MoneyText(
                                        r.$2,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── 6-month trend ─────────────────────────────────────────────────────

class _Trend extends StatefulWidget {
  const _Trend({required this.points});

  final List<TrendPoint> points;

  @override
  State<_Trend> createState() => _TrendState();
}

class _TrendState extends State<_Trend> {
  int? _selected;

  @override
  void didUpdateWidget(_Trend old) {
    super.didUpdateWidget(old);
    if (old.points.lastOrNull?.month != widget.points.lastOrNull?.month) {
      _selected = null; // month changed → back to the newest bar
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final locale = _locale(context);
    final sel = _selected ?? widget.points.length - 1;
    final p = widget.points[sel];
    Widget key(Color c, String label, double v) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('$label ', style: textTheme.bodySmall),
        MoneyText(
          v,
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.homeTrend),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Legend doubles as the readout for the tapped month.
                Text(
                  DateFormat.yMMMM(locale).format(p.month),
                  style: textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    key(palette.income, l.homeIncome, p.income),
                    key(palette.expense, l.homeExpense, p.expense),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PairedBarChart(
                  height: 80,
                  colorA: palette.income,
                  colorB: palette.expense,
                  selected: sel,
                  onSelect: (i) => setState(() => _selected = i),
                  groups: [
                    for (final t in widget.points)
                      BarPair(
                        label: DateFormat.MMM(locale).format(t.month),
                        a: t.income,
                        b: t.expense,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Budgets · debts · goals ───────────────────────────────────────────

class _Tiles extends StatelessWidget {
  const _Tiles({required this.d});

  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = d.budgets;
    final debts = d.debts;
    final goals = d.savingGoals;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              title: l.moreBudgets,
              route: '/budgets',
              value: b.count == 0
                  ? null
                  : Text(
                      l.homeBudgetsUsed(b.utilizationPct.round().toString()),
                    ),
              progress: b.count == 0 ? null : b.utilizationPct / 100,
              caption: b.count == 0
                  ? l.homeBudgetsNone
                  : b.overLimitCount > 0
                  ? l.homeBudgetsOver(b.overLimitCount)
                  : null,
              alert: b.overLimitCount > 0,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Tile(
              title: l.moreDebts,
              route: '/personal-debts',
              value: debts.openCount == 0
                  ? null
                  : MoneyText(debts.net, tone: MoneyTone.signed),
              caption: debts.openCount == 0
                  ? l.homeDebtsNone
                  : l.homeDebtsOpen(debts.openCount),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Tile(
              title: l.moreSavingGoals,
              route: '/saving-goals',
              value: goals.count == 0
                  ? null
                  : Text('${goals.progressPct.round()}%'),
              progress: goals.count == 0 ? null : goals.progressPct / 100,
              caption: goals.count == 0
                  ? l.homeGoalsNone
                  : l.homeGoalsCount(goals.count),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.route,
    this.value,
    this.progress,
    this.caption,
    this.alert = false,
  });

  final String title;
  final String route;
  final Widget? value;

  /// 0..1+ — over 1 paints the bar in the over colour.
  final double? progress;
  final String? caption;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (value != null)
                DefaultTextStyle.merge(
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  child: value!,
                ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.xs),
                ProgressRow(value: progress!, height: 4),
              ],
              const Spacer(),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 2,
                  style: textTheme.labelSmall?.copyWith(
                    color: alert ? palette.expense : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent ────────────────────────────────────────────────────────────

class _Recent extends StatelessWidget {
  const _Recent({required this.d});

  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l.homeRecentTitle,
          actionLabel: d.recent.isEmpty ? null : l.homeRecentViewAll,
          onAction: d.recent.isEmpty ? null : () => context.go('/transactions'),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: d.recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.homeNoTxYet, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      AddTile(
                        label: l.homeAddFirstTx,
                        variant: AddTileVariant.row,
                        // Same flow as the nav's +.
                        onTap: () => showQuickCreateSheet(context),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final t in d.recent)
                      TransactionTile(transaction: t, showDate: true),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Pending drafts ────────────────────────────────────────────────────

/// "รอยืนยัน N รายการ" — the first two drafts, tap for the page. Hidden
/// when nothing is pending. Drafts aren't in any total on this screen.
class _PendingBlock extends StatelessWidget {
  const _PendingBlock();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = context.watch<PendingCubit>().state.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget row(PendingTransaction p) {
      final d = p.draft;
      final title = (d.note?.trim().isNotEmpty ?? false)
          ? d.note!.trim()
          : l.pendingUntitled;
      return Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ),
          MoneyText(
            d.amount ?? 0,
            tone: switch (d.type) {
              TransactionType.expense => MoneyTone.expense,
              TransactionType.income => MoneyTone.income,
              _ => MoneyTone.plain,
            },
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.primaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/pending'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.pending,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l.pendingBlockTitle(items.length),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      l.homeRecentViewAll,
                      style: textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Icon(
                      AppIcons.chevronRight,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final p in items.take(2)) ...[
                  row(p),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  items.length > 2
                      ? '${l.pendingBlockMore(items.length - 2)} · ${l.pendingNotCounted}'
                      : l.pendingNotCounted,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
