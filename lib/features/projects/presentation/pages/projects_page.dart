import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/project.dart';
import '../cubit/projects_cubit.dart';
import '../widgets/project_common.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _search = TextEditingController();
  final _toolbarOpen = ToolbarToggleState.of('events');
  Timer? _debounce;
  final _scroll = ScrollController();

  bool _fillFailed = false;

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
    _scroll.dispose();
    super.dispose();
  }

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

  void _open(Project p) => context.push('/projects/${p.id}');

  void _loadMore() {
    final cubit = context.read<ProjectsCubit>();
    final l = AppLocalizations.of(context)!;
    Future(() async {
      try {
        await cubit.loadMore();
      } catch (_) {
        _fillFailed = true;
        if (mounted) {
          showAppSnackBar(context, l.uiLoadMoreFailed, tone: Tone.danger);
        }
      }
    });
  }

  /// A page that fits the screen never scrolls, so nothing asks for the next
  /// one: after each update, ask until the list overflows.
  void _fillScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fillFailed || !_scroll.hasClients) return;
      final s = context.read<ProjectsCubit>().state;
      if (s.hasMore &&
          !s.loadingMore &&
          s.status == ProjectsStatus.loaded &&
          _scroll.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  void _create() => context.push('/projects/new');

  String _sortLabel(AppLocalizations l, ProjectSort s) => switch (s) {
    ProjectSort.updatedDesc => l.fpEventsSortRecent,
    ProjectSort.startDateDesc => l.eventStartDateLabel,
    ProjectSort.nameAsc => l.projectsSortName,
  };

  String _subtitle(AppLocalizations l, Project p) => [
    ?projectDateRange(context, p.startDate, p.endDate),
    l.fpEventsRowSpent(moneyString(context, p.totalExpense)),
    l.fpEventsRowShare(moneyString(context, p.myShare)),
  ].join(' · ');

  Widget _row(AppLocalizations l, Project p) {
    final owed = p.myReceivable > 0;
    final owe = p.myPayable > 0;
    return EventListRow(
      name: p.name,
      iconCode: p.iconCode,
      subtitle: _subtitle(l, p),
      amount: owed ? p.myReceivable : (owe ? p.myPayable : 0),
      tone: owed
          ? MoneyTone.income
          : (owe ? MoneyTone.expense : MoneyTone.plain),
      caption: owed ? l.fpEventsOwed : (owe ? l.fpEventsOwe : null),
      dimmed: p.status != ProjectStatus.active,
      onTap: () => _open(p),
    );
  }

  List<SummaryTile> _tiles(
    AppLocalizations l,
    ProjectsState state,
    ProjectListSummary s,
  ) {
    void pick(String f) => context.read<ProjectsCubit>().load(
      statusFilter: state.statusFilter == f ? 'active' : f,
    );
    return [
      SummaryTile(
        label: l.fpEventsTileActive,
        value: '${s.active}',
        tone: SummaryTileTone.green,
        selected: state.statusFilter == 'active',
        onTap: () => pick('active'),
      ),
      SummaryTile(
        label: l.fpEventsTileUnsettled,
        value: '${s.unsettled}',
        tone: SummaryTileTone.amber,
        selected: state.statusFilter == 'unsettled',
        onTap: () => pick('unsettled'),
      ),
      SummaryTile(
        label: l.fpEventsTileEnded,
        value: '${s.ended}',
        selected: state.statusFilter == 'ended',
        onTap: () => pick('ended'),
      ),
    ];
  }

  Widget _summary(AppLocalizations l, ProjectsState state) {
    final s = state.summary ?? const ProjectListSummary();
    return ListSummaryCard(
      caption: l.fpEventsSummaryCaption,
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      actions: [
        ListenableBuilder(
          listenable: _search,
          builder: (context, _) => ToolbarToggleButton(
            state: _toolbarOpen,
            filtered:
                _search.text.isNotEmpty ||
                state.tagIds.isNotEmpty ||
                state.sort != ProjectSort.updatedDesc,
            tooltip: l.commonSearch,
          ),
        ),
      ],
      amount: s.myShareTotal,
      infoLine: AppText(
        l.fpEventsPaidLine(
          moneyString(context, s.paidTotal),
          moneyString(context, s.receivableTotal),
        ),
        role: AppTextRole.caption,
      ),
      tiles: _tiles(l, state, s),
    );
  }

  Widget _toolbar(AppLocalizations l, ProjectsState state) {
    final cubit = context.read<ProjectsCubit>();
    return ListToolbar(
      collapse: _toolbarOpen,
      searchController: _search,
      searchHint: l.projectsSearchHint,
      onSearchChanged: _onSearch,
      chips: [
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
          for (final s in ProjectSort.values)
            SheetOption(value: s, label: _sortLabel(l, s)),
        ],
        builder: (context, toggle) => AppChip(
          label: _sortLabel(l, state.sort),
          icon: AppIcons.sort,
          trailing: AppChipTrailing.dropdown,
          onTap: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.navProjects, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<ProjectsCubit, ProjectsState>(
          builder: (ctx, state) {
            final cubit = ctx.read<ProjectsCubit>();
            if (state.status == ProjectsStatus.loading) _fillFailed = false;
            _fillScreen();
            final firstLoad =
                state.projects.isEmpty &&
                (state.status == ProjectsStatus.initial ||
                    state.status == ProjectsStatus.loading);
            final create = AddTile(label: l.fpEventsCreate, onTap: _create);
            return ListPageBody(
              header: [
                if (state.error != null && state.projects.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: AppMessage(
                      message: l.fpEventsLoadFailed,
                      tone: Tone.warning,
                      actions: [
                        AppMessageAction(
                          label: l.commonRetry,
                          onPressed: cubit.load,
                        ),
                      ],
                    ),
                  ),
                _summary(l, state),
                _toolbar(l, state),
              ],
              loading: firstLoad,
              error: state.projects.isEmpty ? state.error : null,
              isEmpty: state.projects.isEmpty,
              onRetry: cubit.load,
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
              sidePadding: 0,
              rowDividers: true,
              controller: _scroll,
              hasMore: state.hasMore,
              loadingMore: state.loadingMore,
              onLoadMore: _loadMore,
              children: [
                for (final p in state.projects) _row(l, p),
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
