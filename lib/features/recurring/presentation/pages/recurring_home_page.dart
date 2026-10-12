import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring.dart';
import '../../domain/recurring_item.dart';
import '../recurring_rows.dart';
import '../recurring_item_actions.dart';

enum RecurringHomeTab { recurring, upcoming }

/// `/recurring` — the ONE management page (owner 2026-10-13): tabs
/// [รายการประจำ] (the settings, filter ใช้งาน / เก็บถาวร / ทั้งหมด) and
/// [รายการล่วงหน้า] (every upcoming item, one-off + 🔁). Open = one call (the
/// shown tab's); the other tab loads the first time it shows; a filter switch
/// is one call; pull-to-refresh re-runs it (the BE's due check runs inside
/// every recurring read).
class RecurringHomePage extends StatefulWidget {
  const RecurringHomePage({
    this.initialTab = RecurringHomeTab.recurring,
    super.key,
  });

  final RecurringHomeTab initialTab;

  @override
  State<RecurringHomePage> createState() => _RecurringHomePageState();
}

class _RecurringHomePageState extends State<RecurringHomePage> {
  late RecurringHomeTab _tab = widget.initialTab;
  late final PageController _pager = PageController(
    initialPage: RecurringHomeTab.values.indexOf(widget.initialTab),
  );

  // ── รายการประจำ ────────────────────────────────────────────────────
  RecurringFilter _filter = RecurringFilter.current;
  RecurringList? _list;
  bool _listLoading = false;
  Object? _listError;

  // ── รายการล่วงหน้า ──────────────────────────────────────────────────
  ItemPage? _upcoming;
  bool _upcomingLoading = false;
  bool _upcomingMore = false;
  Object? _upcomingError;
  Object? _upcomingMoreError;

  RecurringRepository get _repo => RecurringRepository.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTab(_tab);
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /// The tab's first load (each tab loads once, lazily).
  void _loadTab(RecurringHomeTab t) {
    switch (t) {
      case RecurringHomeTab.recurring:
        if (_list == null && !_listLoading) _loadList();
      case RecurringHomeTab.upcoming:
        if (_upcoming == null && !_upcomingLoading) _loadUpcoming();
    }
  }

  Future<void> _loadList() async {
    setState(() {
      _listLoading = true;
      _listError = null;
    });
    try {
      final list = await _repo.list(filter: _filter);
      if (mounted) setState(() => _list = list);
    } catch (e, st) {
      if (mounted) setState(() => _listError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  void _setFilter(RecurringFilter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _list = null;
    });
    _loadList();
  }

  Future<void> _loadUpcoming() async {
    setState(() {
      _upcomingLoading = true;
      _upcomingError = null;
    });
    try {
      final page = await _repo.upcoming();
      if (mounted) setState(() => _upcoming = page);
    } catch (e, st) {
      if (mounted) setState(() => _upcomingError = ApiException.from(e, st));
    } finally {
      if (mounted) setState(() => _upcomingLoading = false);
    }
  }

  Future<void> _loadMoreUpcoming() async {
    final current = _upcoming;
    if (current == null || !current.hasMore || _upcomingMore) return;
    setState(() {
      _upcomingMore = true;
      _upcomingMoreError = null;
    });
    try {
      final next = await _repo.upcoming(page: current.page + 1);
      if (mounted) setState(() => _upcoming = next.after(current));
    } catch (e, st) {
      if (mounted) {
        setState(() => _upcomingMoreError = ApiException.from(e, st));
      }
    } finally {
      if (mounted) setState(() => _upcomingMore = false);
    }
  }

  /// A recurring page / the settings page returns what changed: reload the
  /// list only then (a recurring write moves the upcoming items too).
  Future<void> _open(Future<Object?> Function() push) async {
    final changed = await push();
    // RecurringPage → bool; the settings page → a RecurringSettingsResult.
    if (changed != null && changed != false && mounted) {
      // Reload what has been shown; the other tab loads when it shows.
      if (_list != null) _loadList();
      if (_upcoming != null) _loadUpcoming();
    }
  }

  /// An upcoming item changed through its actions: patch it in place.
  void _applyUpcoming(ItemWriteResult r) {
    final current = _upcoming;
    if (current == null) return;
    setState(
      () => _upcoming = ItemPage(
        items: [
          for (final i in r.applyTo(current.items))
            if (i.state == OccurrenceState.upcoming) i,
        ],
        page: current.page,
        totalPages: current.totalPages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.recurringTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: TabbedListPageBody<RecurringHomeTab>(
          tabs: [
            AppTab(
              value: RecurringHomeTab.recurring,
              label: l.recurringTabRecurring,
            ),
            AppTab(
              value: RecurringHomeTab.upcoming,
              label: l.recurringTabUpcoming,
            ),
          ],
          selected: _tab,
          onChanged: (t) {
            setState(() => _tab = t);
            _loadTab(t);
          },
          controller: _pager,
          pageBuilder: (context, tab) => switch (tab) {
            RecurringHomeTab.recurring => _recurringTab(l),
            RecurringHomeTab.upcoming => _upcomingTab(l),
          },
        ),
      ),
    );
  }

  Widget _recurringTab(AppLocalizations l) {
    final list = _list;
    final items = list?.items ?? const <Recurring>[];
    final counts = list?.counts ?? const <String, int>{};
    return ListPageBody(
      // No data yet = loading (skeleton) until the call answers or fails.
      loading: list == null && _listError == null,
      error: list == null ? _listError : null,
      isEmpty: items.isEmpty,
      onRetry: _loadList,
      rowDividers: true,
      header: [
        ListToolbar(
          chips: [
            for (final f in RecurringFilter.values)
              AppChip(
                label: switch (f) {
                  RecurringFilter.current => l.recurringFilterCurrent,
                  RecurringFilter.archived => l.recurringFilterArchived,
                  RecurringFilter.all => l.recurringFilterAll,
                },
                count: counts[f.toJson()] ?? 0,
                selected: _filter == f,
                onTap: () => _setFilter(f),
              ),
          ],
        ),
      ],
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: _filter == RecurringFilter.archived
            ? l.recurringArchivedEmpty
            : l.recurringEmptyTitle,
        message: l.recurringEmptyMessage,
        cta: _filter == RecurringFilter.archived
            ? null
            : AddTile(
                label: l.recurringAdd,
                onTap: () => _open(() => context.push('/recurring/new')),
              ),
      ),
      children: [
        for (final r in items)
          RecurringRow(
            recurring: r,
            onTap: () => _open(() => context.push('/recurring/${r.id}')),
          ),
        if (_filter != RecurringFilter.archived)
          AddTile(
            label: l.recurringAdd,
            onTap: () => _open(() => context.push('/recurring/new')),
          ),
      ],
    );
  }

  Widget _upcomingTab(AppLocalizations l) {
    final page = _upcoming;
    final items = page?.items ?? const <RecurringItem>[];
    return ListPageBody(
      loading: page == null && _upcomingError == null,
      error: page == null ? _upcomingError : null,
      isEmpty: items.isEmpty,
      onRetry: _loadUpcoming,
      rowDividers: true,
      hasMore: page?.hasMore ?? false,
      loadingMore: _upcomingMore,
      onLoadMore: _loadMoreUpcoming,
      loadMoreError: _upcomingMoreError,
      onRetryMore: _loadMoreUpcoming,
      empty: EmptyView(
        icon: AppIcons.scheduled,
        title: l.upcomingEmptyTitle,
        message: l.upcomingEmptyMessage,
      ),
      children: [
        for (final group in groupItemsByDate(items)) ...[
          DateGroupHeader(label: itemDateLabel(context, group.date)),
          for (final item in group.items)
            RecurringItemActions(
              item: item,
              onChanged: _applyUpcoming,
              onOpenRecurring: item.recurring == null
                  ? null
                  : () => _open(
                      () => context.push('/recurring/${item.recurring!.id}'),
                    ),
              builder: (context, open) =>
                  RecurringItemRow(item: item, showParent: true, onTap: open),
            ),
        ],
      ],
    );
  }
}
