import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/domain/notification.dart';
import '../../../notifications/presentation/cubit/notifications_inbox_cubit.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../../notifications/presentation/notification_actions.dart';
import '../../../notifications/presentation/widgets/notification_tile.dart';
import '../../../pending/domain/pending_transaction.dart';
import '../../../pending/presentation/cubit/pending_cubit.dart';
import '../../../saving_goals/presentation/cubit/saving_goals_cubit.dart';
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

  /// The first-load skeleton's slot heights = the real cards' heights for a
  /// typical home (net worth, nothing waiting, the month bar, the month card,
  /// the donut + trend cards, the tiles row). Kept honest by
  /// `test/features/home/home_skeleton_geometry_test.dart`.
  static const skeletonShape = DashboardSkeletonShape(
    snapshots: [108],
    kpis: [94],
    charts: [184, 240],
    tilesHeight: 132,
  );

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Swiping sideways moves the month (owner 2026-10-10) — left = next,
/// right = previous. Left on the current month (no next) falls through to
/// the shell's tab swipe → รายการ.
class _HomePageState extends State<HomePage> implements ShellSwipeHandler {
  Map<ShellTab, ShellSwipeHandler>? _swipeHandlers;

  @override
  bool canSwipe(int dir) =>
      // `month` null = the current month: nothing after it.
      dir < 0 || context.read<DashboardCubit>().state.month != null;

  @override
  void onSwipe(int dir) => context.read<DashboardCubit>().shiftMonth(dir);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _swipeHandlers = ShellSwipeScope.maybeOf(context)?..[ShellTab.home] = this;
  }

  @override
  void dispose() {
    if (_swipeHandlers?[ShellTab.home] == this) {
      _swipeHandlers!.remove(ShellTab.home);
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Home = ONE call: the dashboard carries the rows (full refs), the
      // drafts, the notifications to answer and the badges. App-scoped
      // cubit (the More hub reads it too).
      context.read<DashboardCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) => TabRootScaffold(
    title: AppLocalizations.of(context)!.navDashboard,
    // The inbox's own cubit, for "ต้องจัดการ"'s notifications — rows act
    // on it exactly as they do in the inbox (NotificationActions).
    body: BlocProvider(
      // Seeded from the dashboard's attention block (no call of its own).
      create: (ctx) {
        final cubit = NotificationsInboxCubit(
          repository: ctx.read<NotificationsRepository>(),
        );
        final d = ctx.read<DashboardCubit>().state.data;
        if (d != null) {
          cubit.seed(
            d.attention.items,
            unreadCount: d.badges.unreadNotifications,
          );
        }
        return cubit;
      },
      child: const _HomeView(),
    ),
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
        // Notifications: the badge (polled, and refreshed by the inbox)
        // moving means something changed elsewhere → re-fetch ours.
        BlocListener<UnreadBadgeCubit, int>(
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        // The dashboard answered: its attention block seeds the inbox cubit
        // the rows act on, and its badges the bell + the drafts count.
        BlocListener<DashboardCubit, DashboardState>(
          listenWhen: (a, b) => b.data != null && a.data != b.data,
          listener: (c, s) {
            final d = s.data!;
            c.read<NotificationsInboxCubit>().seed(
              d.attention.items,
              unreadCount: d.badges.unreadNotifications,
            );
            c.read<UnreadBadgeCubit>().setCount(d.badges.unreadNotifications);
            c.read<PendingCubit>().setKnownTotal(d.badges.pendingDrafts);
          },
        ),
        // Acting here: keep the badge in step, and surface row-action
        // failures like the inbox does.
        BlocListener<NotificationsInboxCubit, InboxState>(
          listenWhen: (a, b) =>
              a.unreadCount != b.unreadCount || a.error != b.error,
          listener: (c, s) {
            c.read<UnreadBadgeCubit>().setCount(s.unreadCount);
            if (s.error != null && s.status != InboxStatus.error) {
              showAppSnackBar(c, s.errorMessage!, tone: Tone.danger);
            }
          },
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();
          // The Dashboard template: snapshot ("right now"), the month bar,
          // then the month-scoped kpis · charts · tiles · lists.
          final d = state.data;
          return DashboardPageBody(
            loading:
                state.status == DashboardStatus.initial ||
                state.status == DashboardStatus.loading,
            error: state.error,
            isEmpty: d == null,
            onRetry: cubit.load,
            refreshing: state.status == DashboardStatus.loading,
            skeletonShape: HomePage.skeletonShape,
            // Stale data + a failed load → the banner, not a snackbar.
            banner: state.status == DashboardStatus.error
                ? l.homeLoadError
                : null,
            // "Right now" first: net worth, then everything waiting on the
            // user (owner 2026-10-10) — none of it follows the selected
            // month.
            snapshot: d == null
                ? const []
                : [
                    _NetWorthCard(netWorth: d.netWorth),
                    _TodoSection(upcoming: d.upcoming, pending: d.pending),
                  ],
            // The month bar heads the month-scoped blocks below it; it
            // never dims (the month is what's loading).
            period: d == null ? null : _MonthBar(month: d.month),
            kpis: d == null
                ? const []
                : [
                    _MonthSlide(
                      month: d.month,
                      child: _MonthCard(
                        current: d.summary,
                        previous: d.previous,
                      ),
                    ),
                  ],
            charts: d == null
                ? const []
                : [
                    _MonthSlide(
                      month: d.month,
                      child: _WhereItWent(d: d),
                    ),
                    _MonthSlide(
                      month: d.month,
                      child: _Trend(points: d.trend),
                    ),
                  ],
            tiles: d == null ? null : _Tiles(d: d),
            lists: d == null ? const [] : [_Recent(d: d)],
          );
        },
      ),
    );
  }
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

// ── Month picker ──────────────────────────────────────────────────────

/// The month as a compact centred pill — `‹ ตุลาคม 2026 ▾ ›` ([StepperPill.month]:
/// ‹ › step, the label opens the month picker) — + 👁 at the right. Never
/// past the current month. No spinner — the content below dims while a
/// month loads.
class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    return Stack(
      alignment: Alignment.center,
      children: [
        StepperPill.month(
          value: month,
          last: DateTime.now(),
          onChanged: cubit.setMonth,
        ),
        if (kMoneyPrivacyEnabled)
          const Align(
            alignment: Alignment.centerRight,
            child: MoneyVisibilityToggle(),
          ),
      ],
    );
  }
}

/// A month-scoped block: when the month changes (swipe, ‹ ›, the picker)
/// the new month's numbers slide in from its side — a later month from the
/// right, an earlier one from the left — as they arrive. Fades only under
/// reduced motion; a refresh of the same month doesn't animate.
class _MonthSlide extends StatefulWidget {
  const _MonthSlide({required this.month, required this.child});

  final DateTime month;
  final Widget child;

  @override
  State<_MonthSlide> createState() => _MonthSlideState();
}

class _MonthSlideState extends State<_MonthSlide>
    with SingleTickerProviderStateMixin {
  /// Entry slide, as a fraction of the block's width (the tab switch's).
  static const _shift = 0.06;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.chrome,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _ctrl,
    curve: AppDurations.chromeCurve,
  );
  int _side = 0;

  @override
  void didUpdateWidget(_MonthSlide old) {
    super.didUpdateWidget(old);
    final side = widget.month.compareTo(old.month).sign;
    if (side == 0) return;
    _side = side;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: _curve.drive(
          Tween<Offset>(
            begin: Offset(still ? 0 : _side * _shift, 0),
            end: Offset.zero,
          ),
        ),
        child: widget.child,
      ),
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
    final palette = Theme.of(context).extension<AppColors>()!;
    final muted = textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    // The wallet-card look (owner 2026-10-09) — the page's lead card.
    return AppCard(
      style: AppCardStyle.tinted,
      color: palette.primary,
      glyph: AppIcons.wallet,
      glyphSize: 132,
      margin: EdgeInsets.zero,
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
                color: palette.primary,
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
    return AppCard(
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
                  AppIcon(
                    pct > 0
                        ? AppIcons.trendUp
                        : pct < 0
                        ? AppIcons.trendDown
                        : AppIcons.trendFlat,
                    size: AppIconSize.sm,
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

// ── Coming up (a "ต้องจัดการ" group) ───────────────────────────────────

/// One subscription / installment / card due — overdue ones get a red
/// edge. Tap → its schedule or card.
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
      child: AppCard(
        margin: EdgeInsets.zero,
        borderColor: item.overdue ? palette.expense : null,
        borderWidth: item.overdue ? 1.5 : null,
        padding: const EdgeInsets.all(AppSpacing.sm),
        onTap: () => openPage(
          context,
          // A recurring card carries the item's id only: the upcoming tab.
          isCard ? '/accounts/${item.id}' : '/recurring?tab=upcoming',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              when,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: item.overdue ? palette.expense : scheme.onSurfaceVariant,
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
        // No "ดูทั้งหมด" here (owner 2026-10-09) — each slice links to its
        // own rows; the recent list below keeps the one way to the full list.
        SectionHeader(title: l.homeWhereMoneyWent),
        AppCard(
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
                              AppCard(
                                style: AppCardStyle.flat,
                                radius: BorderRadius.circular(AppRadius.sm),
                                onTap: r.$4 == null
                                    ? null
                                    : () => context.push('/browse?${r.$4}'),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    _colorKey(r.$3),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        r.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall,
                                      ),
                                    ),
                                    MoneyText(r.$2, style: textTheme.bodySmall),
                                  ],
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
        _colorKey(c),
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
        AppCard(
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
    // The เพิ่มเติม hub's group colours + icons, so a tile reads as the same
    // feature there (owner 2026-10-09).
    final groups = ModuleColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              title: l.moreBudgets,
              icon: AppIcons.budget,
              tint: groups.planning,
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
              icon: AppIcons.debt,
              tint: groups.people,
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
              icon: AppIcons.savingGoal,
              tint: groups.planning,
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
    required this.icon,
    required this.tint,
    required this.route,
    this.value,
    this.progress,
    this.caption,
    this.alert = false,
  });

  final String title;
  final IconData icon;

  /// The feature's group colour (ModuleColors).
  final Color tint;
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
    return AppCard(
      style: AppCardStyle.tinted,
      color: tint,
      glyph: icon,
      glyphSize: 64,
      margin: EdgeInsets.zero,
      onTap: () => openPage(context, route),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: icon,
              color: tint,
              size: 28,
              shape: IconTileShape.rounded,
              style: IconTileStyle.solid,
            ),
            IconTile.gap,
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
              ProgressRow(value: progress!, height: 4, color: tint),
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
    return SectionCard(
      first: true,
      title: l.homeRecentTitle,
      trailing: d.recent.isEmpty
          ? null
          : AppButton(
              label: l.homeRecentViewAll,
              variant: AppButtonVariant.text,
              onPressed: () => context.go('/transactions'),
            ),
      children: d.recent.isEmpty
          ? [
              Padding(
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
              ),
            ]
          : [
              for (final t in d.recent)
                TransactionTile(transaction: t, showDate: true),
              // Add right under the list — same as a wallet's รายการ tab.
              AddTile(
                label: l.navAddTransaction,
                variant: AddTileVariant.row,
                onTap: () => showQuickCreateSheet(context),
              ),
            ],
    );
  }
}

// ── ต้องจัดการ ─────────────────────────────────────────────────────────

/// "ต้องจัดการ" — everything waiting on the user, in one section (owner
/// 2026-10-10): drafts to confirm, notifications to answer, payments
/// coming up. Each group hides when empty; the section hides when all
/// are. None of it follows the selected month.
class _TodoSection extends StatelessWidget {
  const _TodoSection({required this.upcoming, required this.pending});

  final UpcomingBlock upcoming;
  final PendingBlock pending;

  /// Notification rows shown here: unread, or still awaiting an answer.
  static List<AppNotification> _waiting(InboxState s) => [
    for (final n in s.notifications)
      if (n.dismissedAt == null &&
          (n.isUnread || NotificationTile.awaitsAnswer(n)))
        n,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final drafts = pending.items;
    final notes = _waiting(context.watch<NotificationsInboxCubit>().state);
    // Unread may run past the first page — the badge knows the total.
    final noteCount = math.max(
      context.watch<UnreadBadgeCubit>().state,
      notes.length,
    );
    final soon = upcoming.items;
    if (drafts.isEmpty && notes.isEmpty && soon.isEmpty) {
      return const SizedBox.shrink();
    }
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l.homeTodoTitle,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.lg,
            0,
            0,
          ),
        ),
        if (drafts.isNotEmpty)
          _TodoGroup(
            icon: AppIcons.pending,
            title: l.homeTodoPending,
            count: pending.total,
            onViewAll: () => openPage(context, '/pending'),
            child: _DraftsCard(drafts: drafts, total: pending.total),
          ),
        if (notes.isNotEmpty)
          _TodoGroup(
            icon: AppIcons.notifications,
            title: l.notificationsTitle,
            count: noteCount,
            onViewAll: () => openPage(context, '/notifications'),
            child: _NotificationsCard(notes: notes, total: noteCount),
          ),
        if (soon.isNotEmpty)
          _TodoGroup(
            icon: AppIcons.scheduled,
            title: l.homeTodoComingUp,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${l.homeComingUpWindow(upcoming.days)}  ', style: muted),
                MoneyText(-upcoming.totalExpense, tone: MoneyTone.signed),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            child: SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: soon.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => _UpcomingCard(item: soon[i]),
              ),
            ),
          ),
      ],
    );
  }
}

/// One "ต้องจัดการ" group: a [SectionHeader] (title · count, "ดูทั้งหมด ›" or a
/// [trailing] figure), then its compact content — the same treatment for all
/// three so they read as one family.
class _TodoGroup extends StatelessWidget {
  const _TodoGroup({
    required this.icon,
    required this.title,
    required this.child,
    this.count,
    this.onViewAll,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final int? count;
  final VoidCallback? onViewAll;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            leading: AppIcon(
              icon,
              size: AppIconSize.md,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: title,
            count: count,
            actionLabel: l.homeRecentViewAll,
            onAction: onViewAll,
            trailing: trailing,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, 0, 0),
          ),
          child,
        ],
      ),
    );
  }
}

/// รอยืนยัน — the first two drafts + "+ อีก N" (tap → the pending tab).
/// Drafts aren't in any total on this screen.
class _DraftsCard extends StatelessWidget {
  const _DraftsCard({required this.drafts, required this.total});

  final List<PendingTransaction> drafts;

  /// All drafts waiting — may be more than [drafts].
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget row(PendingTransaction p) {
      final d = p.draft;
      // The draft's own title ("what for") first, else its category.
      final description = d.description?.trim() ?? '';
      final title = description.isNotEmpty
          ? description
          : p.resolved.category?.name ?? l.pendingUntitled;
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

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => openPage(context, '/pending'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in drafts.take(2)) ...[
            row(p),
            const SizedBox(height: AppSpacing.xxs),
          ],
          Text(
            total > 2
                ? '${l.pendingBlockMore(total - 2)} · ${l.pendingNotCounted}'
                : l.pendingNotCounted,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// การแจ้งเตือน — the latest three waiting rows with their one-tap
/// actions (the inbox's own [NotificationActions]) + "+ อีก N".
class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({required this.notes, required this.total});

  final List<AppNotification> notes;

  /// Unread / waiting in all — may be more than [notes].
  final int total;

  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final shown = notes.take(_shown).toList();
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in shown)
            NotificationTile(
              notification: n,
              onTap: (notif) => NotificationActions.tap(context, notif),
              onAccept: (_) => NotificationActions.accept(context, n),
              onReject: (_) => NotificationActions.reject(context, n),
            ),
          if (total > shown.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                l.pendingBlockMore(total - shown.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 10 px rounded colour square of a chart key / legend row.
Widget _colorKey(Color color) => ClipRRect(
  borderRadius: BorderRadius.circular(3),
  child: SizedBox.square(dimension: 10, child: ColoredBox(color: color)),
);
