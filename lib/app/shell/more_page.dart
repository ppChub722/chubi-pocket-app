import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/ui.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../../features/home/domain/dashboard.dart';
import '../../features/home/presentation/cubit/dashboard_cubit.dart';
import '../../features/projects/presentation/cubit/projects_cubit.dart';
import '../../features/tags/presentation/cubit/tags_cubit.dart';

/// `/more` — root of the เพิ่มเติม tab: every feature without its own tab,
/// as big cards grouped by purpose. Pages opened from here stack inside
/// this tab (its own navigator), so other tabs keep their place.
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
    final groups = <(String, List<_MoreEntry>)>[
      (
        l.moreGroupLibrary,
        [
          _MoreEntry(
            AppIcons.category,
            l.moreCategories,
            count(categories) ?? l.moreCategoriesDesc,
            '/categories',
            Tone.primary,
          ),
          _MoreEntry(
            AppIcons.tag,
            l.moreTags,
            count(tags) ?? l.moreTagsDesc,
            '/tags',
            Tone.info,
          ),
        ],
      ),
      (
        l.moreGroupPeople,
        [
          _MoreEntry(
            AppIcons.contact,
            l.moreContacts,
            count(contacts) ?? l.moreContactsDesc,
            '/contacts',
            Tone.success,
          ),
          _MoreEntry(
            AppIcons.project,
            l.moreProjects,
            count(projects) ?? l.moreProjectsDesc,
            '/projects',
            Tone.warning,
          ),
          _MoreEntry(
            AppIcons.debt,
            l.moreDebts,
            debts == null || debts.openCount == 0
                ? l.moreDebtsDesc
                : l.moreLiveDebts(
                    moneyString(context, debts.owedToMe),
                    moneyString(context, debts.iOwe),
                  ),
            '/personal-debts',
            Tone.expense,
          ),
        ],
      ),
      (
        l.moreGroupPlanning,
        [
          _MoreEntry(
            AppIcons.budget,
            l.moreBudgets,
            budgets == null || budgets.count == 0
                ? l.moreBudgetsDesc
                : l.homeBudgetsUsed(budgets.utilizationPct.round().toString()),
            '/budgets',
            Tone.income,
          ),
          _MoreEntry(
            AppIcons.savingGoal,
            l.moreSavingGoals,
            goals == null || goals.count == 0
                ? l.moreSavingGoalsDesc
                : '${goals.progressPct.round()}% · ${l.homeGoalsCount(goals.count)}',
            '/saving-goals',
            Tone.info,
          ),
          _MoreEntry(
            AppIcons.scheduled,
            l.moreScheduled,
            dueSoon == null || dueSoon == 0
                ? l.moreScheduledDesc
                : l.moreLiveDueSoon(dueSoon, d!.upcoming.days),
            '/scheduled-transactions',
            Tone.primary,
          ),
        ],
      ),
    ];

    return ListView(
      // Bottom padding keeps the last row clear of the docked `+` FAB.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        for (final (title, entries) in groups) ...[
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
            children: [for (final e in entries) _MoreCard(entry: e)],
          ),
        ],
      ],
    );
  }
}

class _MoreEntry {
  const _MoreEntry(this.icon, this.title, this.subtitle, this.route, this.tone);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Tone tone;
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.entry});

  final _MoreEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tint = entry.tone.color(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: tint.withValues(alpha: 0.25)),
      ),
      child: DecoratedBox(
        // Each feature gets its own colour: a soft wash from the top-left.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint.withValues(alpha: 0.16),
              tint.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: InkWell(
          onTap: () => context.push(entry.route),
          child: Stack(
            children: [
              // Large faded glyph in the corner — depth without clutter.
              Positioned(
                right: -14,
                bottom: -18,
                child: Icon(
                  entry.icon,
                  size: 88,
                  color: tint.withValues(alpha: 0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tint,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(entry.icon, size: 22, color: Colors.white),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}
