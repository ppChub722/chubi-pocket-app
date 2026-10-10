import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/project_common.dart';

enum _Sort { recent, name }

/// `/projects` — card-style list (§12a): search, status (all five), sort,
/// and a dashed "+ สร้างใหม่" tile at the end (§1.2 — no top-bar add).
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String _query = '';
  _Sort _sort = _Sort.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectsCubit>().load();
    });
  }

  List<Project> _shown(List<Project> all) {
    final q = _query.trim().toLowerCase();
    final list = all
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              (p.type?.toLowerCase().contains(q) ?? false),
        )
        .toList();
    if (_sort == _Sort.name) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  Future<void> _open(Project p) async {
    await context.push('/projects/${p.id}');
    if (mounted) context.read<ProjectsCubit>().load();
  }

  void _create() => context.push('/projects/new');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusLabels = <String, String>{
      'active': l.projectStatusActive,
      'completed': l.projectStatusCompleted,
      'cancelled': l.projectStatusCancelled,
      'archived': l.projectStatusArchived,
      'all': l.projectsStatusAll,
    };
    return Scaffold(
      appBar: AppTopBar(title: l.navProjects, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<ProjectsCubit, ProjectsState>(
          builder: (ctx, state) {
            final shown = _shown(state.projects);
            return Column(
              children: [
                // Clear the floating top bar (ctx is inside the body).
                SizedBox(height: MediaQuery.paddingOf(ctx).top),
                AppSearchBar(
                  hint: l.projectsSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
                FilterBar(
                  chips: [
                    OptionMenuAnchor<String>(
                      selected: state.statusFilter,
                      onSelected: (v) =>
                          ctx.read<ProjectsCubit>().load(statusFilter: v),
                      options: [
                        for (final e in statusLabels.entries)
                          SheetOption(value: e.key, label: e.value),
                      ],
                      builder: (context, toggle) => FilterDropdownChip(
                        label: l.projectsStatusLabel,
                        valueLabel: statusLabels[state.statusFilter],
                        active: state.statusFilter != 'active',
                        onTap: toggle,
                      ),
                    ),
                  ],
                  trailing: SortChip<_Sort>(
                    selected: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    options: [
                      SortOption(_Sort.recent, l.projectsSortRecent),
                      SortOption(_Sort.name, l.projectsSortName),
                    ],
                  ),
                ),
                Expanded(
                  child: AsyncStateView(
                    loading:
                        state.status == ProjectsStatus.initial ||
                        state.status == ProjectsStatus.loading,
                    error: state.error,
                    isEmpty: state.projects.isEmpty,
                    onRetry: ctx.read<ProjectsCubit>().load,
                    // No top padding: the bar is already cleared above.
                    skeleton: ListView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(ctx).bottom,
                      ),
                      children: [
                        for (var i = 0; i < 5; i++) const SkeletonListTile(),
                      ],
                    ),
                    // Another status filter with no rows → the list's no-match.
                    empty: state.statusFilter == 'active'
                        ? EmptyView(
                            icon: AppIcons.project,
                            title: l.projectsEmptyTitle,
                            message: l.projectsEmptyMessage,
                            cta: AddTile(
                              label: l.projectsCreateNew,
                              onTap: _create,
                            ),
                          )
                        : null,
                    builder: (context) => PullToRefresh(
                      onRefresh: () => ctx.read<ProjectsCubit>().load(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          96 + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          if (shown.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                l.projectsNoMatch,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          for (final p in shown) ...[
                            _ProjectCard(project: p, onTap: () => _open(p)),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          AddTile(label: l.projectsCreateNew, onTap: _create),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final p = project;
    final meta = [
      l.projectsMembersCount(p.membersCount),
      if (p.plannedAmount != null)
        l.projectMetaPlanned(moneyString(context, p.plannedAmount!)),
      if (p.type?.isNotEmpty ?? false) p.type!,
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Opacity(
                opacity: p.isLocked ? 0.6 : 1,
                child: IconDisplay(
                  type: IconType.project,
                  size: 44,
                  iconCode: p.iconCode,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (p.description?.trim().isNotEmpty ?? false)
                      Text(
                        p.description!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ProjectStatusPill(status: p.status, dense: true),
            ],
          ),
        ),
      ),
    );
  }
}
