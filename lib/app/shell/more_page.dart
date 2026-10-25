import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'tab_nav.dart';
import 'tab_root_scaffold.dart';
import '../../core/network/api_client.dart';
import '../../features/me_counts/cubit/me_counts_cubit.dart';
import '../../features/me_counts/data/me_counts_repository.dart';

/// `/more` — the เพิ่มเติม hub: every feature without a nav slot, as big cards
/// grouped by purpose.
class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    @visibleForTesting this.counts,
    @visibleForTesting this.isOn,
    @visibleForTesting this.topBar,
  });

  /// Tests: a ready cubit instead of the one built from [ApiClient].
  final MeCountsCubit? counts;

  final bool Function(ShellTab)? isOn;

  final PreferredSizeWidget? topBar;

  @override
  Widget build(BuildContext context) {
    final view = _MoreView(isOn: isOn ?? (t) => t.enabled, topBar: topBar);
    final given = counts;
    if (given != null) return BlocProvider.value(value: given, child: view);
    return BlocProvider(
      create: (context) => MeCountsCubit(
        repository: MeCountsRepository(client: context.read<ApiClient>()),
      )..load(),
      child: view,
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView({required this.isOn, this.topBar});

  final bool Function(ShellTab) isOn;
  final PreferredSizeWidget? topBar;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.watch<MeCountsCubit>().state.counts;
    final groupColors = ModuleColors.of(context);
    final budgetPct = c == null || c.budgets == 0 ? 0 : c.budgetUtilizationPct;
    final goalPct = c == null || c.goals == 0 ? 0 : c.goalsProgressPct;
    final hasDebts = c != null && c.openDebts > 0;
    final owedToMe = hasDebts ? c.owedToMe : 0;
    final iOwe = hasDebts ? c.iOwe : 0;
    _MoreEntry entry(ShellTab tab) => switch (tab) {
      ShellTab.categories => _MoreEntry(
        AppIcons.category,
        l.moreCategories,
        l.moreCategoriesDesc,
        '/categories',
      ),
      ShellTab.tags => _MoreEntry(
        AppIcons.tag,
        l.moreTags,
        l.moreTagsDesc,
        '/tags',
      ),
      ShellTab.contacts => _MoreEntry(
        AppIcons.contact,
        l.moreContacts,
        l.moreContactsDesc,
        '/contacts',
      ),
      ShellTab.projects => _MoreEntry(
        AppIcons.project,
        l.moreProjects,
        l.moreProjectsDesc,
        '/projects',
        statuses: [
          if ((c?.activeEvents ?? 0) > 0)
            TileStatus(l.moreChipOpenEvents(c!.activeEvents), tone: Tone.info),
        ],
      ),
      ShellTab.debts => _MoreEntry(
        AppIcons.debt,
        l.moreDebts,
        l.moreDebtsDesc,
        '/personal-debts',
        statuses: [
          if (owedToMe > 0)
            TileStatus(
              l.moreChipReceivable(moneyString(context, owedToMe)),
              tone: Tone.success,
            ),
          if (iOwe > 0)
            TileStatus(
              l.moreChipPayable(moneyString(context, iOwe)),
              tone: Tone.warning,
            ),
        ],
      ),
      ShellTab.budgets => _MoreEntry(
        AppIcons.budget,
        l.moreBudgets,
        l.moreBudgetsDesc,
        '/budgets',
        statuses: [
          if (budgetPct >= 100)
            TileStatus(l.moreChipOverBudget, tone: Tone.danger)
          else if (budgetPct >= 80)
            TileStatus(l.moreChipNearBudget, tone: Tone.warning),
        ],
      ),
      ShellTab.savingGoals => _MoreEntry(
        AppIcons.savingGoal,
        l.moreSavingGoals,
        l.moreSavingGoalsDesc,
        '/saving-goals',
        statuses: [
          if (goalPct >= 100)
            TileStatus(l.moreChipGoalReached, tone: Tone.success)
          else if (goalPct >= 80)
            TileStatus(l.moreChipNearGoal, tone: Tone.success),
        ],
      ),
      ShellTab.recurring => _MoreEntry(
        AppIcons.recurring,
        l.moreRecurring,
        l.moreRecurringDesc,
        '/recurring',
        statuses: [
          if ((c?.recurringUpcoming ?? 0) > 0)
            TileStatus(
              l.moreChipDueSoon(c!.recurringUpcoming),
              tone: Tone.warning,
            ),
        ],
      ),
      _ => throw ArgumentError('$tab has no เพิ่มเติม card'),
    };
    List<_MoreEntry> cards(ShellRow row) => [
      for (final tab in row.all)
        if (isOn(tab)) entry(tab),
    ];
    final main = <_MoreEntry>[
      _MoreEntry(
        AppIcons.dashboard,
        l.navDashboard,
        l.moreDashboardDesc,
        '/',
        main: true,
      ),
      _MoreEntry(
        AppIcons.transactions,
        l.navTransactions,
        l.moreTransactionsDesc,
        '/transactions',
        main: true,
      ),
      _MoreEntry(
        AppIcons.wallet,
        l.navAccounts,
        l.moreWalletsDesc,
        '/accounts',
        main: true,
      ),
      if (isOn(ShellTab.pending))
        _MoreEntry(
          AppIcons.pending,
          l.pendingTitle,
          l.morePendingDesc,
          '/pending',
          main: true,
          statuses: [
            if ((c?.pendingDrafts ?? 0) > 0)
              TileStatus(
                l.moreChipPending(c!.pendingDrafts),
                tone: Tone.warning,
              ),
          ],
        ),
      if (isOn(ShellTab.notifications))
        _MoreEntry(
          AppIcons.notifications,
          l.notificationsTitle,
          l.moreNotificationsDesc,
          '/notifications',
          main: true,
          statuses: [
            if ((c?.unreadNotifications ?? 0) > 0)
              TileStatus(
                l.moreChipUnread(c!.unreadNotifications),
                tone: Tone.info,
              ),
          ],
        ),
      _MoreEntry(
        AppIcons.settings,
        l.moreSettings,
        l.moreSettingsDesc,
        '/settings',
        main: true,
      ),
    ];
    final primary = Theme.of(context).colorScheme.primary;
    final groups = <(String, Color, List<_MoreEntry>)>[
      (l.moreGroupPlan, groupColors.planning, cards(ShellRow.planning)),
      (l.moreGroupOthers, groupColors.people, cards(ShellRow.people)),
      (l.moreGroupSetup, groupColors.library, cards(ShellRow.library)),
      (l.moreGroupMain, primary, main),
    ].where((g) => g.$3.isNotEmpty).toList();

    return TabRootScaffold(
      topBar: topBar,
      body: Builder(
        builder: (context) => PullToRefresh(
          onRefresh: context.read<MeCountsCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.paddingOf(context).top + AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              for (final (title, tint, entries) in groups) ...[
                SectionHeader(
                  title: title,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.lg,
                    0,
                    AppSpacing.sm,
                  ),
                ),
                CardGrid(
                  children: [
                    for (final e in entries)
                      TileCard(
                        icon: e.icon,
                        title: e.title,
                        subtitle: e.subtitle,
                        statuses: e.statuses,
                        color: tint,
                        onTap: () => e.main
                            ? openPage(context, e.route)
                            : context.go(e.route),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreEntry {
  const _MoreEntry(
    this.icon,
    this.title,
    this.subtitle,
    this.route, {
    this.main = false,
    this.statuses = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final List<TileStatus> statuses;

  final bool main;
}
