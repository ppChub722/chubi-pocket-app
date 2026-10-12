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

/// `/more` — the เพิ่มเติม hub: every feature without a nav slot, as big
/// cards grouped by purpose. Each card opens the feature's own tab
/// ([ShellTab]); back at that tab's root returns here.
///
/// Card subtitles show a live count when one is known — all from ONE
/// `GET /me/counts` per open / pull-to-refresh — and fall back to the
/// static description otherwise.
class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    @visibleForTesting this.counts,
    @visibleForTesting this.isOn,
    @visibleForTesting this.topBar,
  });

  /// Tests: a ready cubit instead of the one built from [ApiClient].
  final MeCountsCubit? counts;

  /// Tests: which modules are on; the app uses [ShellTab.enabled].
  final bool Function(ShellTab)? isOn;

  /// Tests: replaces the shell's top bar.
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
    String? count(int? n) => n == null || n == 0 ? null : l.moreLiveCount(n);
    // One colour per group, from the active theme (ModuleColors).
    final groupColors = ModuleColors.of(context);
    _MoreEntry entry(ShellTab tab) => switch (tab) {
      ShellTab.categories => _MoreEntry(
        AppIcons.category,
        l.moreCategories,
        count(c?.categories) ?? l.moreCategoriesDesc,
        '/categories',
      ),
      ShellTab.tags => _MoreEntry(
        AppIcons.tag,
        l.moreTags,
        count(c?.tags) ?? l.moreTagsDesc,
        '/tags',
      ),
      ShellTab.contacts => _MoreEntry(
        AppIcons.contact,
        l.moreContacts,
        count(c?.contacts) ?? l.moreContactsDesc,
        '/contacts',
      ),
      ShellTab.projects => _MoreEntry(
        AppIcons.project,
        l.moreProjects,
        count(c?.activeEvents) ?? l.moreProjectsDesc,
        '/projects',
      ),
      ShellTab.debts => _MoreEntry(
        AppIcons.debt,
        l.moreDebts,
        c == null || c.openDebts == 0
            ? l.moreDebtsDesc
            : l.moreLiveDebts(
                moneyString(context, c.owedToMe),
                moneyString(context, c.iOwe),
              ),
        '/personal-debts',
      ),
      ShellTab.budgets => _MoreEntry(
        AppIcons.budget,
        l.moreBudgets,
        c == null || c.budgets == 0
            ? l.moreBudgetsDesc
            : l.homeBudgetsUsed(c.budgetUtilizationPct.round().toString()),
        '/budgets',
      ),
      ShellTab.savingGoals => _MoreEntry(
        AppIcons.savingGoal,
        l.moreSavingGoals,
        c == null || c.goals == 0
            ? l.moreSavingGoalsDesc
            : '${c.goalsProgressPct.round()}% · ${l.homeGoalsCount(c.goals)}',
        '/saving-goals',
      ),
      ShellTab.recurring => _MoreEntry(
        AppIcons.recurring,
        l.moreRecurring,
        c == null || c.recurringUpcoming == 0
            ? l.moreRecurringDesc
            : l.moreLiveDueSoon(c.recurringUpcoming, 14),
        '/recurring',
      ),
      _ => throw ArgumentError('$tab has no เพิ่มเติม card'),
    };
    // Cards come from the เพิ่มเติม rows (ShellRow), so the hub, the swipe
    // order and the module switches (AppModules) always agree. A section
    // with every module off is left out.
    List<_MoreEntry> cards(ShellRow row) => [
      for (final tab in row.all)
        if (isOn(tab)) entry(tab),
    ];
    // The main menu: the nav + top-bar pages (no ShellRow — they have their
    // own swipe rows), opened through openPage.
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
          count(c?.pendingDrafts) ?? l.morePendingDesc,
          '/pending',
          main: true,
        ),
      if (isOn(ShellTab.notifications))
        _MoreEntry(
          AppIcons.notifications,
          l.notificationsTitle,
          c == null || c.unreadNotifications == 0
              ? l.moreNotificationsDesc
              : l.moreLiveUnread(c.unreadNotifications),
          '/notifications',
          main: true,
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

    // No title chip on the hub. Builder: the top inset must be read inside
    // the scaffold body.
    return TabRootScaffold(
      topBar: topBar,
      body: Builder(
        builder: (context) => PullToRefresh(
          onRefresh: context.read<MeCountsCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Top: the body sits under the transparent top bar.
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
                        color: tint,
                        // Its own tab, opened fresh at its root (owner 2026-10-09).
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  /// A main-menu entry (nav / top-bar page): opened through [openPage].
  final bool main;
}
