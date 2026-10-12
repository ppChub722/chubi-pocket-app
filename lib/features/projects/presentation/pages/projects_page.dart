import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/project_common.dart';

/// `/projects` — the events list (§12a): search, status, my tags and sort
/// all run on the server (paged); hairline [EventCard] rows and a dashed
/// "+ สร้างใหม่" tile at the end (§1.2 — no top-bar add).
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ProjectsCubit>();
    _search.text = cubit.state.query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cubit.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// One call per pause in typing.
  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) context.read<ProjectsCubit>().load(query: v.trim());
    });
  }

  Future<void> _pickTags(ProjectsState state) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<ProjectsCubit>();
    final picked = await showTagPickerSheet(
      context,
      selected: state.tagIds.toSet(),
      title: l.transactionFormTagsLabel,
      allowCreate: false,
    );
    if (picked == null || !mounted) return;
    await cubit.load(tagIds: picked.toList());
  }

  // The event page patches the list from its writes: no reload on return.
  void _open(Project p) => context.push('/projects/${p.id}');

  /// Fired from a scroll notification (maybe mid-layout): run after it.
  void _loadMore() {
    final cubit = context.read<ProjectsCubit>();
    final l = AppLocalizations.of(context)!;
    Future(() async {
      try {
        await cubit.loadMore();
      } catch (_) {
        if (mounted) {
          showAppSnackBar(context, l.uiLoadMoreFailed, tone: Tone.danger);
        }
      }
    });
  }

  void _create() => context.push('/projects/new');

  /// The user's currency (one per user; events are in it).
  String get _symbol {
    final auth = context.read<AuthCubit>().state;
    return Currencies.symbolOf(
      auth is AuthAuthenticated ? auth.user.currency : 'THB',
    );
  }

  Widget _row(AppLocalizations l, Project p, String symbol) {
    final planned = p.plannedAmount;
    final member = p.myMemberId != null;
    return EventCard(
      name: p.name,
      iconCode: p.iconCode,
      description: p.description,
      tags: [for (final t in p.tags) EventTagRef(t.name, iconCode: t.iconCode)],
      statusLabel: projectStatusLabel(l, p.status),
      statusTone: projectStatusTone(p.status),
      meta: [
        l.projectsMembersCount(p.membersCount),
        ?projectDateRange(context, p.startDate, p.endDate),
      ].join(' · '),
      // Spent vs the plan (expense − income, the summary's spent_net).
      progress: planned == null || planned <= 0
          ? null
          : (p.totalExpense - p.totalIncome) / planned,
      progressLabel: planned == null
          ? null
          : l.projectMetaPlanned(moneyString(context, planned, symbol: symbol)),
      myNet: member ? p.myNet : null,
      symbol: symbol,
      dimmed: p.isLocked,
      onTap: () => _open(p),
    );
  }

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
    final sortLabels = <ProjectSort, String>{
      ProjectSort.updatedDesc: l.projectsSortRecent,
      ProjectSort.startDateDesc: l.eventStartDateLabel,
      ProjectSort.nameAsc: l.projectsSortName,
    };
    return Scaffold(
      appBar: AppTopBar(title: l.navProjects, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<ProjectsCubit, ProjectsState>(
          builder: (ctx, state) {
            final cubit = ctx.read<ProjectsCubit>();
            // The skeleton only while nothing is on screen (first load).
            final firstLoad =
                state.projects.isEmpty &&
                (state.status == ProjectsStatus.initial ||
                    state.status == ProjectsStatus.loading);
            final create = AddTile(label: l.projectsCreateNew, onTap: _create);
            return ListPageBody(
              header: [
                ListToolbar(
                  searchController: _search,
                  searchHint: l.projectsSearchHint,
                  onSearchChanged: _onSearch,
                  chips: [
                    OptionMenuAnchor<String>(
                      selected: state.statusFilter,
                      onSelected: (v) => cubit.load(statusFilter: v),
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
                    AppChip(
                      label: l.transactionFormTagsLabel,
                      icon: AppIcons.tag,
                      selected: state.tagIds.isNotEmpty,
                      count: state.tagIds.length,
                      trailing: AppChipTrailing.dropdown,
                      onTap: () => _pickTags(state),
                    ),
                  ],
                  trailing: OptionMenuAnchor<ProjectSort>(
                    selected: state.sort,
                    onSelected: (s) => cubit.load(sort: s),
                    options: [
                      for (final e in sortLabels.entries)
                        SheetOption(value: e.key, label: e.value),
                    ],
                    builder: (context, toggle) => AppChip(
                      label: sortLabels[state.sort]!,
                      icon: AppIcons.sort,
                      trailing: AppChipTrailing.dropdown,
                      onTap: toggle,
                    ),
                  ),
                ),
              ],
              loading: firstLoad,
              error: state.projects.isEmpty ? state.error : null,
              isEmpty: state.projects.isEmpty,
              onRetry: cubit.load,
              // Nothing at all → create; filtered / searched to nothing →
              // the no-match view (create there too).
              empty: state.filtered
                  ? EmptyView(
                      icon: AppIcons.project,
                      title: l.projectsNoMatch,
                      message: '',
                      cta: create,
                    )
                  : EmptyView(
                      icon: AppIcons.project,
                      title: l.projectsEmptyTitle,
                      message: l.projectsEmptyMessage,
                      cta: create,
                    ),
              topInset: AppSpacing.xs,
              // Hairline rows, edge to edge (list rows aren't boxed).
              sidePadding: 0,
              rowDividers: true,
              hasMore: state.hasMore,
              loadingMore: state.loadingMore,
              onLoadMore: _loadMore,
              children: [
                for (final p in state.projects) _row(l, p, _symbol),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: create,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
