import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/module_colors.dart';
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
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/domain/notification.dart';
import '../../../notifications/presentation/cubit/notifications_inbox_cubit.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../../notifications/presentation/notification_actions.dart';
import '../../../notifications/presentation/widgets/notification_tile.dart';
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
    // The inbox's own cubit, for "ต้องจัดการ"'s notifications — rows act
    // on it exactly as they do in the inbox (NotificationActions).
    body: BlocProvider(
      create: (ctx) => NotificationsInboxCubit(
        repository: ctx.read<NotificationsRepository>(),
      )..load(),
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
        BlocListener<PersonalDebtsCubit, PersonalDebtsState>(
          listenWhen: (a, b) => a.debts != b.debts,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        BlocListener<ScheduledTransactionsCubit, ScheduledTransactionsState>(
          listenWhen: (a, b) => a.entries != b.entries,
          listener: (c, _) => c.read<DashboardCubit>().markStale(),
        ),
        // Notifications: the badge (polled, and refreshed by the inbox)
        // moving means something changed elsewhere → re-fetch ours.
        BlocListener<UnreadBadgeCubit, int>(
          listener: (c, _) => c.read<NotificationsInboxCubit>().load(),
        ),
        // Acting here: keep the badge in step, and surface row-action
        // failures like the inbox does.
        BlocListener<NotificationsInboxCubit, InboxState>(
          listenWhen: (a, b) =>
              a.unreadCount != b.unreadCount || a.error != b.error,
          listener: (c, s) {
            c.read<UnreadBadgeCubit>().refresh();
            if (s.error != null && s.status != InboxStatus.error) {
              showAppSnackBar(c, s.errorMessage!, tone: Tone.danger);
            }
          },
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
                onRefresh: () => Future.wait([
                  cubit.load(),
                  context.read<NotificationsInboxCubit>().load(),
                  context.read<PendingCubit>().load(),
                ]),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Body sits under the transparent top bar.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    MediaQuery.paddingOf(context).top + AppSpacing.xs,
                    AppSpacing.lg,
                    96 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    if (state.status == DashboardStatus.error) ...[
                      MessageBanner(
                        message: l.homeLoadError,
                        tone: Tone.danger,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // "Right now" first: net worth, then everything waiting
                    // on the user (owner 2026-10-10) — none of it follows
                    // the selected month.
                    _Dimmed(
                      loading: state.status == DashboardStatus.loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _NetWorthCard(netWorth: d.netWorth),
                          _TodoSection(upcoming: d.upcoming),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // The month bar heads the month-scoped blocks below it;
                    // it never dims (the month is what's loading).
                    _MonthBar(month: d.month),
                    const SizedBox(height: AppSpacing.sm),
                    _Dimmed(
                      loading: state.status == DashboardStatus.loading,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MonthSlide(
                            month: d.month,
                            child: _MonthCard(
                              current: d.summary,
                              previous: d.previous,
                            ),
                          ),
                          _MonthSlide(
                            month: d.month,
                            child: _WhereItWent(d: d),
                          ),
                          _MonthSlide(
                            month: d.month,
                            child: _Trend(points: d.trend),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _Tiles(d: d),
                          _Recent(d: d),
                        ],
                      ),
                    ),
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

/// The month as a compact centred pill — `‹ ตุลาคม 2026 ▾ ›` ([MonthPill]:
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
        MonthPill(
          month: month,
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

/// Loading another month (or refreshing): the old numbers dim instead of a
/// spinner beside the month.
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.loading, required this.child});

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: AppDurations.fast,
    opacity: loading ? 0.5 : 1,
    child: child,
  );
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
    return TintedCard(
      tint: palette.primary,
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
          onTap: () => openPage(
            context,
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
        // No "ดูทั้งหมด" here (owner 2026-10-09) — each slice links to its
        // own rows; the recent list below keeps the one way to the full list.
        SectionHeader(title: l.homeWhereMoneyWent),
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
    return TintedCard(
      tint: tint,
      glyph: icon,
      glyphSize: 64,
      margin: EdgeInsets.zero,
      onTap: () => openPage(context, route),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIconBadge(icon: icon, tint: tint, size: 28),
            TintedIconBadge.gap,
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
        // Add right under the list — same as a wallet's รายการ tab.
        if (d.recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AddTile(
            label: l.navAddTransaction,
            variant: AddTileVariant.row,
            onTap: () => showQuickCreateSheet(context),
          ),
        ],
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
  const _TodoSection({required this.upcoming});

  final UpcomingBlock upcoming;

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
    final drafts = context.watch<PendingCubit>().state.items;
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
            count: drafts.length,
            onViewAll: () => openPage(context, '/pending'),
            child: _DraftsCard(drafts: drafts),
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

/// One "ต้องจัดการ" group: an icon + title · count sub-header (with
/// "ดูทั้งหมด ›" or a [trailing] figure), then its compact content — the
/// same treatment for all three so they read as one family.
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    ' · $count',
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                ?trailing,
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.homeRecentViewAll),
                        const Icon(AppIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
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
  const _DraftsCard({required this.drafts});

  final List<PendingTransaction> drafts;

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
          : context.read<CategoriesCubit>().byId(d.categoryId ?? '')?.name ??
                l.pendingUntitled;
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

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPage(context, '/pending'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final p in drafts.take(2)) ...[
                row(p),
                const SizedBox(height: AppSpacing.xxs),
              ],
              Text(
                drafts.length > 2
                    ? '${l.pendingBlockMore(drafts.length - 2)} · ${l.pendingNotCounted}'
                    : l.pendingNotCounted,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
