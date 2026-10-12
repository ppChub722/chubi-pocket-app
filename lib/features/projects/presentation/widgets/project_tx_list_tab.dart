import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/projects_repository.dart';
import '../../domain/project.dart';
import 'project_common.dart';
import 'project_tx_tiles.dart';

enum _Sort { date, amount }

extension on _Sort {
  String get wire => switch (this) {
    _Sort.date => 'date_desc',
    _Sort.amount => 'amount_desc',
  };
}

/// "รายการ" tab (§12b): search, [ประเภท ▾] [แท็ก ×] [เฉพาะฉัน] + sort, rows
/// grouped under date headers when sorted by date. Unfiltered it shows the
/// page's board (the detail call's first page, more pages on scroll); any
/// filter / sort runs on the server (`GET /projects/:id/transactions`),
/// paged. A dashed "+ เพิ่มรายการ" tile heads the rows when [onAdd] is set.
class ProjectTxListTab extends StatefulWidget {
  const ProjectTxListTab({
    required this.view,
    required this.onChanged,
    this.onPatch,
    this.onLoadMore,
    this.onAdd,
    this.tagFilter,
    this.onTagFilterChanged,
    this.onAddTagToMine,
    this.focusBillId,
    this.onFocused,
    super.key,
  });

  final ProjectView view;

  /// Pull-to-refresh / a reload: the page's one "open" call.
  final Future<void> Function() onChanged;

  /// A write's patch: the page applies it.
  final ValueChanged<EventPatch>? onPatch;

  /// The page's next board page (the unfiltered list).
  final Future<void> Function()? onLoadMore;

  /// Adds a row to the project; null = the user can't (locked / viewer).
  final VoidCallback? onAdd;

  /// Only bills with this event tag (null = all); owned by the page so a
  /// tag chip elsewhere can set it.
  final BoardTag? tagFilter;
  final ValueChanged<BoardTag?>? onTagFilterChanged;

  /// "+ เพิ่มเข้าแท็กของฉัน" on a bill's tag.
  final ValueChanged<BoardTag>? onAddTagToMine;

  /// A bill to scroll to once it's on screen (tx detail's event link);
  /// [onFocused] says it's done.
  final String? focusBillId;
  final VoidCallback? onFocused;

  @override
  State<ProjectTxListTab> createState() => _ProjectTxListTabState();
}

class _ProjectTxListTabState extends State<ProjectTxListTab> {
  static const _perPage = 30;

  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _type; // null = all, 'expense', 'income'
  bool _mine = false;
  _Sort _sort = _Sort.date;

  /// The server's filtered rows (flat) while a filter / sort is on; null =
  /// the page's board.
  List<ProjectTransaction>? _rows;
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  ApiException? _error;

  /// Bumped on every new query: a late answer for an older one is dropped.
  int _seq = 0;

  /// The [ProjectTxListTab.focusBillId] row, scrolled to after its frame.
  final _focusKey = GlobalKey();
  bool _focusScheduled = false;

  /// The bill already scrolled to (never twice).
  String? _focusDone;

  void _scheduleFocus() {
    if (_focusScheduled || _focusDone == widget.focusBillId) return;
    _focusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusScheduled = false;
      final target = _focusKey.currentContext;
      if (!mounted || target == null) return;
      _focusDone = widget.focusBillId;
      Scrollable.ensureVisible(
        target,
        alignment: 0.3,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppDurations.chrome,
      );
      widget.onFocused?.call();
    });
  }

  bool get _filtered =>
      _query.isNotEmpty ||
      _type != null ||
      _mine ||
      widget.tagFilter != null ||
      _sort != _Sort.date;

  @override
  void initState() {
    super.initState();
    if (_filtered) _reload();
  }

  @override
  void didUpdateWidget(ProjectTxListTab old) {
    super.didUpdateWidget(old);
    if (old.tagFilter?.id != widget.tagFilter?.id) {
      _reload();
    } else if (!identical(old.view, widget.view) && _rows != null) {
      // A write on the page: keep the filtered rows in step with it.
      _rows = _patched(_rows!, old.view, widget.view);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// [rows] with every row the page's write changed swapped for its new
  /// copy; rows the page had and no longer has (a removed bill / split)
  /// drop out; rows only in the filtered results stay.
  static List<ProjectTransaction> _patched(
    List<ProjectTransaction> rows,
    ProjectView before,
    ProjectView after,
  ) {
    final now = {for (final t in after.txs) t.id: t};
    final had = {for (final t in before.txs) t.id};
    return [
      for (final t in rows)
        if (now[t.id] case final fresh?) fresh else if (!had.contains(t.id)) t,
    ];
  }

  Future<void> _reload() async {
    final seq = ++_seq;
    if (!_filtered) {
      setState(() {
        _rows = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _fetch(1);
      if (!mounted || seq != _seq) return;
      setState(() {
        _rows = rows;
        _page = 1;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _error = ApiException.from(e, st);
        _loading = false;
      });
    }
  }

  Future<List<ProjectTransaction>> _fetch(int page) async {
    final rows = await context.read<ProjectsRepository>().listTransactions(
      widget.view.project.id,
      page: page,
      perPage: _perPage,
      type: _type,
      mine: _mine,
      q: _query,
      tagId: widget.tagFilter?.id,
      sort: _sort.wire,
    );
    _hasMore = rows.where((t) => t.isParent).length >= _perPage;
    return rows;
  }

  /// Fired from a scroll notification (maybe mid-layout): runs after it.
  void _loadMore() {
    if (_loadingMore) return;
    final pageMore = widget.onLoadMore;
    if (_rows == null && pageMore == null) return;
    if (_rows != null && !_hasMore) return;
    final seq = _seq;
    _loadingMore = true;
    Future(() async {
      try {
        if (_rows == null) {
          await pageMore!();
        } else {
          final more = await _fetch(_page + 1);
          if (!mounted || seq != _seq) return;
          final seen = {for (final t in _rows!) t.id};
          setState(() {
            _rows = [..._rows!, ...more.where((t) => !seen.contains(t.id))];
            _page++;
          });
        }
      } catch (_) {
        if (mounted) {
          final l = AppLocalizations.of(context)!;
          showAppSnackBar(context, l.uiLoadMoreFailed, tone: Tone.danger);
        }
      } finally {
        _loadingMore = false;
        if (mounted) setState(() {});
      }
    });
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _query = v.trim();
      _reload();
    });
  }

  void _set(VoidCallback change) {
    setState(change);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = widget.view;
    final filteredRows = _rows;
    final trees = filteredRows == null
        ? v.trees
        : buildProjectTxTree(filteredRows);
    final typeLabels = {
      'expense': l.projectTxTypeExpense,
      'income': l.projectTxTypeIncome,
    };
    final sortLabels = {
      _Sort.date: l.projectTxSortTime,
      _Sort.amount: l.projectTxSortAmount,
    };

    final rows = <Widget>[];
    String? lastDate;
    for (final t in trees) {
      if (_sort == _Sort.date && t.parent.date != lastDate) {
        lastDate = t.parent.date;
        rows.add(DateGroupHeader(label: projectTxDateLabel(context, lastDate)));
      }
      final focused = t.parent.id == widget.focusBillId;
      final tile = ProjectTxTreeTile(
        tree: t,
        highlighted: focused,
        view: v,
        onChanged: widget.onChanged,
        onPatch: widget.onPatch,
        onShowTag: widget.onTagFilterChanged,
        onAddTagToMine: widget.onAddTagToMine,
      );
      if (focused && _focusDone != widget.focusBillId) {
        rows.add(KeyedSubtree(key: _focusKey, child: tile));
        _scheduleFocus();
      } else {
        rows.add(tile);
      }
    }
    final tag = widget.tagFilter;
    final waiting = _filtered && filteredRows == null;

    // Search + filters pin above the list (the template's header); the rows
    // carry their own side padding.
    return ListPageBody(
      loading: false,
      error: null,
      isEmpty: v.trees.isEmpty && !_filtered,
      onRetry: widget.onChanged,
      topInset: 0,
      clearTopBar: false, // the project page pads the bar itself
      rowDividers: true,
      sidePadding: 0,
      hasMore: filteredRows == null ? v.hasMoreRows : _hasMore,
      loadingMore: _loadingMore,
      onLoadMore: _loadMore,
      header: [
        ListToolbar(
          searchController: _search,
          searchHint: l.projectTxSearchHint,
          onSearchChanged: _onSearch,
          chips: [
            OptionMenuAnchor<String?>(
              selected: _type,
              onSelected: (t) => _set(() => _type = t),
              options: [
                SheetOption(value: null, label: l.projectTxTypeAll),
                for (final e in typeLabels.entries)
                  SheetOption(value: e.key, label: e.value),
              ],
              builder: (context, toggle) => AppChip(
                label: _type == null
                    ? l.projectTxTypeLabel
                    : '${l.projectTxTypeLabel}: ${typeLabels[_type]}',
                selected: _type != null,
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
            ),
            if (tag != null)
              AppChip(
                label: l.eventTagFilter(tag.name),
                selected: true,
                trailing: AppChipTrailing.remove,
                onRemove: () => widget.onTagFilterChanged?.call(null),
              ),
            AppChip(
              label: l.projectTxOnlyMine,
              selected: _mine,
              onTap: () => _set(() => _mine = !_mine),
            ),
          ],
          trailing: OptionMenuAnchor<_Sort>(
            selected: _sort,
            onSelected: (s) => _set(() => _sort = s),
            options: [
              for (final e in sortLabels.entries)
                SheetOption(value: e.key, label: e.value),
            ],
            builder: (context, toggle) => AppChip(
              label: sortLabels[_sort]!,
              icon: AppIcons.sort,
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          ),
        ),
      ],
      empty: EmptyView(
        icon: AppIcons.empty,
        title: l.projectTxEmpty,
        message: '',
        cta: widget.onAdd == null
            ? null
            : AddTile(label: l.projectAddTransaction, onTap: widget.onAdd),
      ),
      children: [
        if (widget.onAdd != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AddTile(
              label: l.projectAddTransaction,
              variant: AddTileVariant.row,
              onTap: widget.onAdd,
            ),
          ),
        if (waiting && _error != null)
          ErrorView(error: _error!, onRetry: _reload)
        else if (waiting || (_loading && filteredRows == null))
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: LoadingView(),
          )
        else if (trees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: EmptyView(
              icon: AppIcons.empty,
              title: l.projectTxNoMatch,
              message: '',
            ),
          )
        else
          ...rows,
      ],
    );
  }
}
