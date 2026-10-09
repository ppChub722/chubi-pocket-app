import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/module_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/ui.dart';
import 'tab_nav.dart';
import 'tab_root_scaffold.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../../features/home/domain/dashboard.dart';
import '../../features/home/presentation/cubit/dashboard_cubit.dart';
import '../../features/projects/presentation/cubit/projects_cubit.dart';
import '../../features/tags/presentation/cubit/tags_cubit.dart';

/// `/more` — the เพิ่มเติม hub: every feature without a nav slot, as big
/// cards grouped by purpose. Each card opens the feature's own tab
/// ([ShellTab]); back at that tab's root returns here.
///
/// Card subtitles show a live figure when one is known — counts from the
/// shared cubits, planning figures from the app-scoped [DashboardCubit]
/// ("ค้าง 3 รายการ", "ใช้ไป 62%") — and fall back to the static
/// description otherwise.
class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardCubit>().loadIfNeeded();
      context.read<CategoriesCubit>().loadIfNeeded();
      context.read<TagsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final d = context.watch<DashboardCubit>().state.data;
    final categories = context.watch<CategoriesCubit>().state.categories;
    final tags = context.watch<TagsCubit>().state.tags;
    final contacts = context.watch<ContactsCubit>().state.contacts;
    final projects = context.watch<ProjectsCubit>().state.projects;
    String? count(List list) =>
        list.isEmpty ? null : l.moreLiveCount(list.length);
    final debts = d?.debts;
    final budgets = d?.budgets;
    final goals = d?.savingGoals;
    final dueSoon = d?.upcoming.items
        .where((i) => i.kind == UpcomingKind.scheduled)
        .length;
    // One colour per group, from the active theme (ModuleColors).
    final groupColors = ModuleColors.of(context);
    _MoreEntry entry(ShellTab tab) => switch (tab) {
      ShellTab.categories => _MoreEntry(
        AppIcons.category,
        l.moreCategories,
        count(categories) ?? l.moreCategoriesDesc,
        '/categories',
      ),
      ShellTab.tags => _MoreEntry(
        AppIcons.tag,
        l.moreTags,
        count(tags) ?? l.moreTagsDesc,
        '/tags',
      ),
      ShellTab.contacts => _MoreEntry(
        AppIcons.contact,
        l.moreContacts,
        count(contacts) ?? l.moreContactsDesc,
        '/contacts',
      ),
      ShellTab.projects => _MoreEntry(
        AppIcons.project,
        l.moreProjects,
        count(projects) ?? l.moreProjectsDesc,
        '/projects',
      ),
      ShellTab.debts => _MoreEntry(
        AppIcons.debt,
        l.moreDebts,
        debts == null || debts.openCount == 0
            ? l.moreDebtsDesc
            : l.moreLiveDebts(
                moneyString(context, debts.owedToMe),
                moneyString(context, debts.iOwe),
              ),
        '/personal-debts',
      ),
      ShellTab.budgets => _MoreEntry(
        AppIcons.budget,
        l.moreBudgets,
        budgets == null || budgets.count == 0
            ? l.moreBudgetsDesc
            : l.homeBudgetsUsed(budgets.utilizationPct.round().toString()),
        '/budgets',
      ),
      ShellTab.savingGoals => _MoreEntry(
        AppIcons.savingGoal,
        l.moreSavingGoals,
        goals == null || goals.count == 0
            ? l.moreSavingGoalsDesc
            : '${goals.progressPct.round()}% · ${l.homeGoalsCount(goals.count)}',
        '/saving-goals',
      ),
      ShellTab.scheduled => _MoreEntry(
        AppIcons.scheduled,
        l.moreScheduled,
        dueSoon == null || dueSoon == 0
            ? l.moreScheduledDesc
            : l.moreLiveDueSoon(dueSoon, d!.upcoming.days),
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
        builder: (context) => ListView(
          // Top: the body sits under the transparent top bar.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.paddingOf(context).top + AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.huge,
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
              // Fixed card height; column count follows the width (2 on phones,
              // 3–4 on wide screens) so cards never balloon into empty slabs.
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  mainAxisExtent: 124,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                children: [
                  for (final e in entries) _MoreCard(entry: e, tint: tint),
                ],
              ),
            ],
          ],
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

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.entry, required this.tint});

  final _MoreEntry entry;

  /// The group colour.
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Each feature gets its group colour (shared look: TintedCard).
    return TintedCard(
      tint: tint,
      glyph: entry.icon,
      // Its own tab, opened fresh at its root (owner 2026-10-09).
      onTap: () => context.go(entry.route),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TintedIconBadge(icon: entry.icon, tint: tint),
            const Spacer(),
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              entry.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
