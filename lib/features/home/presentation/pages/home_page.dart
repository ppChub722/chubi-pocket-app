import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../budgets/data/budgets_repository.dart';
import '../../../budgets/domain/budget_overview.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../../../saving_goals/data/saving_goals_repository.dart';
import '../../../saving_goals/domain/saving_goal.dart';
import '../../../scheduled_transactions/data/scheduled_transactions_repository.dart';
import '../../../scheduled_transactions/domain/scheduled_upcoming.dart';
import '../../../transactions/data/transactions_repository.dart';
import '../../../transactions/domain/transaction_type.dart';
import '../../../transactions/domain/transactions_summary.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/widgets/period_summary_card.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';

/// Dashboard (§8), top to bottom: net worth (👁) → period summary →
/// budgets → coming up → debts → saving goals → spending by category →
/// recent. Each block fetches on its own and hides itself when it has
/// nothing to show (several requests — a combined `/dashboard` is BE
/// backlog). Pull to refresh reloads all of them.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Bumped on refresh — section keys change, so they refetch.
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      context.read<TransactionsCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<PersonalDebtsCubit>().loadIfNeeded();
    });
  }

  Future<void> _refresh() async {
    setState(() => _tick++);
    await Future.wait([
      context.read<AccountsCubit>().load(),
      context.read<TransactionsCubit>().load(),
      context.read<PersonalDebtsCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsCubit>().state;
    final tx = context.watch<TransactionsCubit>().state;
    final loading = accounts.status == AccountsStatus.loading &&
        accounts.accounts.isEmpty &&
        tx.transactions.isEmpty;
    if (loading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          SkeletonBox(height: 120),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: 140),
          SizedBox(height: AppSpacing.lg),
          SkeletonListTile(),
          SkeletonListTile(),
        ],
      );
    }
    return PullToRefresh(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 96),
        children: [
          const _NetWorthCard(),
          const SizedBox(height: AppSpacing.lg),
          PeriodSummaryCard(key: ValueKey('sum$_tick')),
          _BudgetsSection(key: ValueKey('bud$_tick')),
          _UpcomingSection(key: ValueKey('up$_tick')),
          const _DebtsSection(),
          _GoalsSection(key: ValueKey('goal$_tick')),
          _ByCategorySection(key: ValueKey('cat$_tick')),
          const _RecentSection(),
        ],
      ),
    );
  }
}

/// A titled dashboard block with an optional "ดูทั้งหมด ›".
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.onSeeAll});

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          actionLabel: onSeeAll == null ? null : l.homeRecentViewAll,
          onAction: onSeeAll,
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }
}

/// FutureBuilder that renders nothing while loading / on error / when
/// [isEmpty] — dashboard blocks just don't appear.
class _Fetch<T> extends StatefulWidget {
  const _Fetch({required this.load, required this.isEmpty, required this.builder});

  final Future<T> Function(BuildContext) load;
  final bool Function(T) isEmpty;
  final Widget Function(BuildContext, T) builder;

  @override
  State<_Fetch<T>> createState() => _FetchState<T>();
}

class _FetchState<T> extends State<_Fetch<T>> {
  late final Future<T> _future = widget.load(context);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (snap.hasError || d == null || widget.isEmpty(d)) {
          return const SizedBox.shrink();
        }
        return widget.builder(context, d);
      },
    );
  }
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── 1. Net worth ──────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final accounts = context.watch<AccountsCubit>().state.accounts;
    final total = accounts.fold<double>(0, (a, x) => a + x.balance);
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
              Row(
                children: [
                  Text(l.homeNetWorthLabel, style: textTheme.labelLarge),
                  const Spacer(),
                  const MoneyVisibilityToggle(),
                ],
              ),
              MoneyText(
                total,
                style: textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(l.homeNetWorthAccountCount(accounts.length),
                  style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3. Budgets ────────────────────────────────────────────────────────

class _BudgetsSection extends StatelessWidget {
  const _BudgetsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Fetch<BudgetOverview>(
      load: (c) => c.read<BudgetsRepository>().overview(),
      isEmpty: (o) => o.budgets.isEmpty,
      builder: (context, o) {
        final lines = [...o.budgets]
          ..sort((a, b) => b.utilizationPct.compareTo(a.utilizationPct));
        return _Block(
          title: l.moreBudgets,
          onSeeAll: () => context.push('/budgets'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                for (final b in lines.take(3)) ...[
                  Row(
                    children: [
                      Expanded(child: Text(b.categoryName)),
                      if (b.overLimit)
                        const Icon(AppIcons.warning, size: 16),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProgressRow(
                    value: b.amount == 0 ? 0 : b.spent / b.amount,
                    label: l.homeBudgetLine(moneyString(context, b.spent),
                        moneyString(context, b.amount)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 4. Coming up ──────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Fetch<ScheduledUpcoming>(
      load: (c) => c.read<ScheduledTransactionsRepository>().upcoming(days: 7),
      isEmpty: (u) => u.entries.isEmpty,
      builder: (context, u) => _Block(
        title: l.homeUpcoming,
        onSeeAll: () => context.push('/scheduled-transactions'),
        child: Column(
          children: [
            for (final e in u.entries.take(4))
              ListTile(
                leading: const Icon(AppIcons.scheduled),
                title: Text(e.name),
                subtitle: Text(l.homeUpcomingInDays(e.daysUntil)),
                trailing: MoneyText(e.amount),
                onTap: () => context.push('/scheduled-transactions/${e.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 5. Debts ──────────────────────────────────────────────────────────

class _DebtsSection extends StatelessWidget {
  const _DebtsSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final people = context.watch<PersonalDebtsCubit>().state.people;
    final owed = people.fold<double>(0, (a, p) => a + p.owedToMeOpen);
    final owe = people.fold<double>(0, (a, p) => a + p.iOweOpen);
    if (owed == 0 && owe == 0) return const SizedBox.shrink();
    return _Block(
      title: l.moreDebts,
      onSeeAll: () => context.push('/personal-debts'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SummaryStats(stats: [
          SummaryStat(label: l.debtsOwedToMe, amount: owed, tone: MoneyTone.income),
          SummaryStat(label: l.debtsIOwe, amount: owe, tone: MoneyTone.expense),
          SummaryStat(
              label: l.debtsNet,
              amount: owed - owe,
              tone: MoneyTone.signed),
        ]),
      ),
    );
  }
}


// ── 6. Saving goals ───────────────────────────────────────────────────

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Fetch<List<SavingGoal>>(
      load: (c) => c.read<SavingGoalsRepository>().list(),
      isEmpty: (g) => g.isEmpty,
      builder: (context, goals) => _Block(
        title: l.moreSavingGoals,
        onSeeAll: () => context.push('/saving-goals'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (final g in goals.take(3)) ...[
                Align(alignment: Alignment.centerLeft, child: Text(g.name)),
                const SizedBox(height: AppSpacing.xs),
                ProgressRow(
                  value: g.targetAmount == 0
                      ? 0
                      : (g.currentAmount / g.targetAmount).clamp(0, 1),
                  label: l.homeGoalLine(moneyString(context, g.currentAmount),
                      moneyString(context, g.targetAmount)),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 7. Spending by category ───────────────────────────────────────────

class _ByCategorySection extends StatelessWidget {
  const _ByCategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return _Fetch<TransactionsSummary>(
      // `type=expense` is contract §2 — until the BE filters, groups mix
      // income in; `spent` prefers the typed figure once it's sent.
      load: (c) => c.read<TransactionsRepository>().summary(
            from: _ymd(DateTime(now.year, now.month, 1)),
            to: _ymd(DateTime(now.year, now.month + 1, 0)),
            type: TransactionType.expense,
            groupBy: 'category',
          ),
      isEmpty: (s) => s.groups.where((g) => g.spent > 0).isEmpty,
      builder: (context, s) {
        final groups = s.groups.where((g) => g.spent > 0).toList()
          ..sort((a, b) => b.spent.compareTo(a.spent));
        final top = groups.first.spent;
        final palette = Theme.of(context).extension<AppColors>()!;
        return _Block(
          title: l.homeByCategory,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                for (final g in groups.take(5)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(g.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      MoneyText(g.spent),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProgressRow(
                      value: top == 0 ? 0 : g.spent / top,
                      color: palette.expense,
                      height: 6),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 8. Recent ─────────────────────────────────────────────────────────

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final recent =
        context.watch<TransactionsCubit>().state.transactions.take(5).toList();
    return _Block(
      title: l.homeRecentTitle,
      onSeeAll: recent.isEmpty ? null : () => context.go('/transactions'),
      child: recent.isEmpty
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
                    onTap: () => context.push('/transactions/new'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final t in recent)
                  TransactionTile(transaction: t, showDate: true),
              ],
            ),
    );
  }
}
