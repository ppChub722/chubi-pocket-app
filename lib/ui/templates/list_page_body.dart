import 'package:flutter/material.dart';

import '../molecules/app_tab_bar.dart';
import '../molecules/empty_view.dart';
import '../molecules/load_more_error_row.dart';
import '../molecules/page_dots.dart';
import '../organisms/async_state_view.dart';
import '../organisms/divided_rows.dart';
import '../organisms/page_skeletons.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';

/// The ListPage template's body (owner 2026-10-12): every list page is the same
/// skeleton —
///
///   [pinned header: search · filters · selection bar · banners] → the list,
///   with the first-load skeleton, the full-page error + retry, the empty
///   state, pull-to-refresh, paging and clearance for the floating bars.
///
/// The page keeps its own Scaffold / top bar / FAB / edit modes; this widget is
/// the content so loading, error, empty, refresh and paging behave identically
/// on every list.
///
/// - [header]: widgets pinned above the list — an `AppInput.search`, a
///   `FilterBar`, a `ListSelectionBar` (select all + bulk actions + the red
///   trash), an `AppMessage` banner. They don't scroll.
/// - the list itself, one of:
///   * [children] — rows / cards / `SectionHeader`s in order (a grouped list is
///     a flat list with a header before each group);
///   * [builder] — your own scrollable (a `ReorderListScope` list, a tree) when
///     the list needs its own scroll view; the template still gives it the
///     data states and the header.
/// - [loading] / [error] / [isEmpty] / [onRetry]: the data state — see
///   `AsyncStateView`; [empty] is the empty view. The first-load skeleton is
///   the template's own [ListPageSkeleton]; a page only says its shape
///   ([skeletonShape]: rows by default, a cards grid for wallets).
/// - paging: [onLoadMore] fires when the list scrolls near its end (while
///   [hasMore], not [loadingMore] and no [loadMoreError]); [loadingMore]
///   shows two row skeletons at the end (never a spinner); a failed page
///   ([loadMoreError]) shows a "couldn't load more · retry" row at the end
///   instead ([onRetryMore]); the rows already loaded stay.
/// - [footer]: after the last row (a count, "that's all").
/// - tabs (a list split by expense / income …): use [TabbedListPageBody] —
///   an `AppTabBar` over an `AppTabPager`, each tab its own ListPageBody
///   (own empty / refresh state).
/// - [bottomInset] clears the floating bars (the centre + / a chat dial).
class ListPageBody extends StatefulWidget {
  const ListPageBody({
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.empty,
    this.children = const [],
    this.builder,
    this.header = const [],
    this.skeletonShape = const ListSkeletonShape(),
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    this.loadMoreError,
    this.onRetryMore,
    this.footer,
    this.controller,
    this.refreshEnabled = true,
    this.clearTopBar = true,
    this.rowDividers = false,
    this.rowDividerIndent = defaultRowDividerIndent,
    this.rowGap = 0,
    this.topInset = AppSpacing.md,
    this.bottomInset = floatingBarClearance,
    this.sidePadding = AppSpacing.lg,
    super.key,
  }) : assert(
         children == const <Widget>[] || builder == null,
         'give children OR builder, not both',
       );

  final bool loading;
  final Object? error;
  final bool isEmpty;
  final Future<void> Function() onRetry;
  final EmptyView empty;
  final List<Widget> children;

  /// A custom scrollable for the loaded state (reorder / tree lists). It gets
  /// the insets to use as its own scroll padding (side + top + bottom
  /// clearance incl. the system inset), so it matches [children] lists.
  final Widget Function(BuildContext context, EdgeInsets padding)? builder;

  /// Bottom clearance for the floating bars (centre + / chat dial) — use it
  /// for a list that isn't a [ListPageBody] (an edit-mode list) so it ends
  /// where the others do. The system inset is added on top.
  static const double floatingBarClearance = 96;
  final List<Widget> header;

  /// The first-load skeleton's shape (see [ListSkeletonShape]).
  final ListSkeletonShape skeletonShape;

  /// More pages exist on the server.
  final bool hasMore;

  /// The next page is in flight — row skeletons at the end of the list.
  final bool loadingMore;

  /// Called when the list scrolls within ~one screen of its end.
  final VoidCallback? onLoadMore;

  /// The next page failed: the end of the list shows a retry row
  /// ([onRetryMore], else [onLoadMore]) and scrolling stops asking.
  final Object? loadMoreError;
  final VoidCallback? onRetryMore;

  /// After the last row (and the paging row).
  final Widget? footer;
  final ScrollController? controller;

  /// false: no pull-to-refresh (an edit / reorder mode, where a pull would fight the drag).
  final bool refreshEnabled;

  /// Start below the floating top bar (the body sits behind it — its height is
  /// in `MediaQuery.padding.top`): the first header widget, or the first row,
  /// is never hidden by it. Pages must NOT add the bar height themselves. A
  /// list embedded under other content (a tab body) passes false.
  final bool clearTopBar;

  /// Hairlines between consecutive ROWS of [children] (owner 2026-10-12: no
  /// per-day boxes), plus the grouped-list separators: a thick 8 px full-width
  /// band BETWEEN day / section groups and a hairline between a group header
  /// (`DateGroupHeader`, `SectionHeader`) and its first row. The band is full
  /// width only with `sidePadding: 0`. The line starts at [rowDividerIndent] (the
  /// row text) and ends at the side margin.
  final bool rowDividers;
  final double rowDividerIndent;

  /// Card-list mode: this much space between consecutive [children] (cards,
  /// boxed rows), so a page needs no `SizedBox` between them. Ignored with
  /// [rowDividers].
  final double rowGap;

  /// 16 margin + 36 icon + 12 gap — a transaction row's text.
  static const double defaultRowDividerIndent = 64;
  final double topInset;
  final double bottomInset;
  final double sidePadding;

  @override
  State<ListPageBody> createState() => _ListPageBodyState();
}

class _ListPageBodyState extends State<ListPageBody> {
  /// Nested lists (a tab page inside a pager) must not clear the bar again.
  Widget _consumed(Widget child) =>
      MediaQuery.removePadding(context: context, removeTop: true, child: child);

  Widget _refresh(ListPageBody w, Widget child) => w.refreshEnabled
      ? PullToRefresh(onRefresh: w.onRetry, child: child)
      : child;

  bool _onScroll(ScrollNotification n) {
    final more = widget.onLoadMore;
    if (more == null ||
        !widget.hasMore ||
        widget.loadingMore ||
        widget.loadMoreError != null) {
      return false;
    }
    if (n.depth != 0) return false;
    final m = n.metrics;
    if (m.maxScrollExtent - m.pixels < m.viewportDimension) more();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final mq = MediaQuery.paddingOf(context);
    final bar = w.clearTopBar ? mq.top : 0.0;
    final hasHeader = w.header.isNotEmpty;
    final padding = EdgeInsets.fromLTRB(
      w.sidePadding,
      w.topInset + (hasHeader ? 0 : bar),
      w.sidePadding,
      w.bottomInset + mq.bottom,
    );
    final list = AsyncStateView(
      loading: w.loading,
      error: w.error,
      isEmpty: w.isEmpty,
      onRetry: w.onRetry,
      empty: w.empty,
      skeleton: ListPageSkeleton(
        grouped: w.rowDividers,
        rowDividerIndent: w.rowDividerIndent,
        shape: w.skeletonShape,
        padding: padding,
      ),
      builder: (context) => _refresh(
        w,
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child:
              w.builder?.call(context, padding) ??
              ListView(
                controller: w.controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                children: [
                  ...(w.rowDividers
                      ? dividedRows(
                          context,
                          w.children,
                          indent: w.rowDividerIndent,
                        )
                      : w.rowGap > 0
                      ? _gapped(w.children, w.rowGap)
                      : w.children),
                  if (w.loadingMore) ...const [
                    ListRowSkeleton(),
                    ListRowSkeleton(),
                  ] else if (w.loadMoreError != null)
                    LoadMoreErrorRow(onRetry: w.onRetryMore ?? w.onLoadMore),
                  ?w.footer,
                  const PageDotsFooter(),
                ],
              ),
        ),
      ),
    );
    if (!hasHeader) return _consumed(list);
    return _consumed(
      Padding(
        padding: EdgeInsets.only(top: bar),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...w.header,
            Expanded(child: list),
          ],
        ),
      ),
    );
  }
}

/// A list page split into tabs (categories: expense / income): the pinned
/// [header] widgets, then an `AppTabBar` over an `AppTabPager` whose pages are
/// each a [ListPageBody] built by [pageBuilder] — so every tab has its own
/// loading / empty / refresh / paging state and scroll position.
class TabbedListPageBody<T> extends StatelessWidget {
  const TabbedListPageBody({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    required this.controller,
    required this.pageBuilder,
    this.header = const [],
    this.headerBelowTabs = false,
    this.topInset = 0,
    this.clearTopBar = true,
    this.swipeEnabled = true,
    this.showPageDots = true,
    super.key,
  });

  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  /// The pager's controller (the page owns and disposes it).
  final PageController controller;

  /// One tab's content — return a [ListPageBody].
  final Widget Function(BuildContext context, T tab) pageBuilder;

  /// Widgets pinned with the tab bar (search, banners) — above it, or under
  /// it when [headerBelowTabs].
  final List<Widget> header;
  final bool headerBelowTabs;

  /// Extra space above everything, on top of the bar clearance.
  final double topInset;

  /// Start below the floating top bar (see [ListPageBody.clearTopBar]).
  final bool clearTopBar;

  /// false while a drag-reorder is running in a tab.
  final bool swipeEnabled;

  /// The page indicator at the end of each tab's list (see [PageDots]).
  final bool showPageDots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height:
              topInset + (clearTopBar ? MediaQuery.paddingOf(context).top : 0),
        ),
        if (!headerBelowTabs) ...header,
        AppTabBar<T>(
          tabs: tabs,
          selected: selected,
          onChanged: onChanged,
          pager: controller,
        ),
        if (headerBelowTabs) ...header,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: AppTabPager<T>(
              values: [for (final t in tabs) t.value],
              selected: selected,
              onChanged: onChanged,
              controller: controller,
              enabled: swipeEnabled,
              showPageDots: showPageDots,
              builder: pageBuilder,
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> _gapped(List<Widget> children, double gap) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) SizedBox(height: gap),
    children[i],
  ],
];
