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
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => MeCountsCubit(
      repository: MeCountsRepository(client: context.read<ApiClient>()),
    )..load(),
    child: const _MoreView(),
  );
}

class _MoreView extends StatelessWidget {
  const _MoreView();

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
      ShellTab.scheduled => _MoreEntry(
        AppIcons.scheduled,
        l.moreScheduled,
        c == null || c.scheduledUpcoming == 0
            ? l.moreScheduledDesc
            : l.moreLiveDueSoon(c.scheduledUpcoming, 14),
        '/scheduled-transactions',
      ),
      _ => throw ArgumentError('$tab has no เพิ่มเติม card'),
    };
    // Sections + cards come from the เพิ่มเติม rows (ShellRow), so the hub,
    // the swipe order and the module switches (AppModules) always agree.
    // A section with every module off is left out.
    final groups = <(String, Color, List<_MoreEntry>)>[
      for (final row in ShellRow.values)
        if (row.inMore && row.tabs.isNotEmpty)
          (
            switch (row) {
              ShellRow.library => l.moreGroupLibrary,
              ShellRow.people => l.moreGroupPeople,
              _ => l.moreGroupPlanning,
            },
            switch (row) {
              ShellRow.library => groupColors.library,
              ShellRow.people => groupColors.people,
              _ => groupColors.planning,
            },
            [for (final tab in row.tabs) entry(tab)],
          ),
    ];

    // No title chip on the hub. Builder: the top inset must be read inside
    // the scaffold body.
    return TabRootScaffold(
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
                        onTap: () => context.go(e.route),
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
  const _MoreEntry(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
