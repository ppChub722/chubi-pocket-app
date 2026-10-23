import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../tags/presentation/widgets/tag_picker.dart';
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
    final picked = await TagPicker.many(
      context,
      selected: state.tagIds.toSet(),
      title: l.transactionFormTagsLabel,
      allowCreate: false,
    );
    if (picked == null || !mounted) return;
    await cubit.load(tagIds: picked.ids.toList());
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

  /// Owed → ได้คืน (green), owe → ต้องจ่าย (red), settled → my share with
  /// เคลียร์แล้ว. A plan adds the budget bar under the row.
  Widget _row(AppLocalizations l, Project p) {
    final owed = p.myReceivable > 0;
    final owe = p.myPayable > 0;
    final planned = p.plannedAmount;
    final left = p.remaining;
    final hasPlan = planned != null && planned > 0 && left != null;
    final over = hasPlan && left < 0;
    String money(double v) => moneyString(context, v);
    return EventListRow(
      key: ValueKey('event:${p.id}'),
      name: p.name,
      iconCode: p.iconCode,
      members: p.membersCount > 0 ? p.membersCount : null,
      status: over
          ? ListRowChip(l.fpEventsOverBudget, tone: Tone.danger)
          : null,
      meta: [
        ?projectDateRange(context, p.startDate, p.endDate),
        if (p.isUnsettled) l.fpEventsRowShare(money(p.myShare)),
      ],
      amount: owed ? p.myReceivable : (owe ? p.myPayable : p.myShare),
      tone: owed
          ? MoneyTone.income
          : (owe ? MoneyTone.expense : MoneyTone.plain),
      caption: owed ? l.fpEventsOwed : (owe ? l.fpEventsOwe : l.debtsEven),
      dimmed: !p.isActive && !p.isUnsettled,
      footer: hasPlan
          ? ProgressRow(
              value: (planned - left) / planned,
              fillLabel: money(planned - left),
              endLabel: money(planned),
              height: 6,
            )
          : null,
      onTap: () => _open(p),
    );
  }

  /// กำลังทำ / จบแล้ว, each under its header; counts and my share are the
  /// loaded rows'.
  List<Widget> _sections(AppLocalizations l, ProjectsState state) {
    final active = [
      for (final p in state.projects)
        if (p.isActive) p,
    ];
    final ended = [
      for (final p in state.projects)
        if (!p.isActive) p,
    ];
    List<Widget> section(String title, List<Project> rows) => [
      if (rows.isNotEmpty) ...[
        SectionHeader(
          key: ValueKey('eventsSection-$title'),
          title: title,
          count: rows.length,
          trailing: AppText(
            l.fpEventsRowShare(
              moneyString(
                context,
                rows.fold<double>(0, (s, p) => s + p.myShare),
              ),
            ),
            role: AppTextRole.caption,
          ),
        ),
        for (final p in rows) _row(l, p),
      ],
    ];
    return [
      ...section(l.fpEventsTileActive, active),
      ...section(l.fpEventsTileEnded, ended),
    ];
  }

  Widget _hero(AppLocalizations l, ProjectsState state) {
    final s = state.summary ?? const ProjectListSummary();
    final palette = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<ProjectsCubit>();
    final net = s.net;
    String money(double v) => moneyString(context, v);
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      header: HeroSummaryHead(
        icon: AppIcons.project,
        label: l.fpEventsHeroNet(s.unsettled),
        amount: MoneyText(net, tone: MoneyTone.signed),
        amountColor: net.abs() <= 0.005
            ? null
            : (net > 0 ? palette.income : palette.expense),
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
          CardActionButton(
            key: const ValueKey('eventsAdd'),
            icon: AppIcons.add,
            tooltip: l.fpEventsCreate,
            onTap: _create,
          ),
        ],
      ),
      content: [
        HeroFactList(
          facts: [
            HeroFact(
              l.fpEventsOwedFact(s.receivable),
              money(s.receivableTotal),
              icon: AppIcons.flowIn,
              iconColor: palette.income,
              color: palette.income,
            ),
            HeroFact(
              l.fpEventsOweFact(s.payable),
              money(s.payableTotal),
              icon: AppIcons.flowOut,
              iconColor: palette.expense,
              color: palette.expense,
            ),
            HeroFact(
              l.fpEventsShareFact(s.active),
              money(s.myShareTotal),
              icon: AppIcons.split,
            ),
          ],
        ),
      ],
      footer: [
        HeroFilterChips(
          filters: [
            for (final (f, label, tone, count) in [
              ('current', l.fpEventsFilterAll, null, s.all),
              ('active', l.fpEventsTileActive, AppChipTone.success, s.active),
              (
                'unsettled',
                l.fpEventsTileUnsettled,
                AppChipTone.warning,
                s.unsettled,
              ),
              ('ended', l.fpEventsTileEnded, AppChipTone.neutral, s.ended),
            ])
              HeroFilter(
                label: label,
                count: count,
                tone: tone,
                selected: state.statusFilter == f,
                onTap: () => cubit.load(statusFilter: f),
              ),
          ],
        ),
      ],
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
                _hero(l, state),
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
              topInset: AppSpacing.sm,
              rowCards: true,
              rowDividers: true,
              rowDividerIndent:
                  AppSpacing.lg + EventListRow.iconSize + AppSpacing.md,
              controller: _scroll,
              hasMore: state.hasMore,
              loadingMore: state.loadingMore,
              onLoadMore: _loadMore,
              children: _sections(l, state),
            );
          },
        ),
      ),
    );
  }
}
