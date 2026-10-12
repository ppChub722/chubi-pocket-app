import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
  final _search = TextEditingController();
  String _query = '';
  _Sort _sort = _Sort.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProjectsCubit>().load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
            final firstLoad =
                state.status == ProjectsStatus.initial ||
                state.status == ProjectsStatus.loading;
            final nothingYet =
                state.projects.isEmpty &&
                state.statusFilter == 'active' &&
                _query.trim().isEmpty;
            final create = AddTile(label: l.projectsCreateNew, onTap: _create);
            return ListPageBody(
              header: [
                ListToolbar(
                  searchController: _search,
                  searchHint: l.projectsSearchHint,
                  onSearchChanged: (v) => setState(() => _query = v),
                  chips: [
                    OptionMenuAnchor<String>(
                      selected: state.statusFilter,
                      onSelected: (v) =>
                          ctx.read<ProjectsCubit>().load(statusFilter: v),
                      options: [
                        for (final e in statusLabels.entries)
                          SheetOption(value: e.key, label: e.value),
                      ],
                      builder: (context, toggle) => AppChip(
                        label:
                            '${l.projectsStatusLabel}: '
                            '${statusLabels[state.statusFilter]}',
                        selected: state.statusFilter != 'active',
                        trailing: AppChipTrailing.dropdown,
                        onTap: toggle,
                      ),
                    ),
                  ],
                  trailing: OptionMenuAnchor<_Sort>(
                    selected: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    options: [
                      SheetOption(
                        value: _Sort.recent,
                        label: l.projectsSortRecent,
                      ),
                      SheetOption(value: _Sort.name, label: l.projectsSortName),
                    ],
                    builder: (context, toggle) => AppChip(
                      label: _sort == _Sort.recent
                          ? l.projectsSortRecent
                          : l.projectsSortName,
                      icon: AppIcons.sort,
                      trailing: AppChipTrailing.dropdown,
                      onTap: toggle,
                    ),
                  ),
                ),
              ],
              loading: firstLoad,
              error: state.error,
              isEmpty: shown.isEmpty,
              onRetry: ctx.read<ProjectsCubit>().load,
              // Nothing at all → create; filtered / searched to nothing →
              // the no-match view.
              empty: nothingYet
                  ? EmptyView(
                      icon: AppIcons.project,
                      title: l.projectsEmptyTitle,
                      message: l.projectsEmptyMessage,
                      cta: create,
                    )
                  : EmptyView(
                      icon: AppIcons.project,
                      title: l.projectsNoMatch,
                      message: '',
                      cta: create,
                    ),
              topInset: AppSpacing.xs,
              children: [
                for (final p in shown) ...[
                  _ProjectCard(project: p, onTap: () => _open(p)),
                  const SizedBox(height: AppSpacing.sm),
                ],
                create,
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
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: ListRow(
        dimmed: p.isLocked,
        onTap: onTap,
        leading: IconDisplay(
          type: IconType.project,
          size: 44,
          iconCode: p.iconCode,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (p.description?.trim().isNotEmpty ?? false)
              Text(
                p.description!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: AppChip(
          label: projectStatusLabel(l, p.status),
          dot: true,
          tone: projectStatusTone(p.status),
          selected: true,
          size: ChipSize.chip,
        ),
      ),
    );
  }
}
