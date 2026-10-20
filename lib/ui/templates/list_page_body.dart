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
    this.scrollHeader = const [],
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
    this.rowCards = false,
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

  final Widget Function(BuildContext context, EdgeInsets padding)? builder;

  static const double floatingBarClearance = 96;
  final List<Widget> header;

  final List<Widget> scrollHeader;

  final ListSkeletonShape skeletonShape;

  final bool hasMore;

  final bool loadingMore;

  final VoidCallback? onLoadMore;

  final Object? loadMoreError;
  final VoidCallback? onRetryMore;

  final Widget? footer;
  final ScrollController? controller;

  /// false: no pull-to-refresh (an edit / reorder mode, where a pull would
  /// fight the drag).
  final bool refreshEnabled;

  final bool clearTopBar;

  final bool rowDividers;

  /// The rows between breaks (date headers) sit in one card each (see
  /// cardedRows); wins over [rowDividers].
  final bool rowCards;
  final double rowDividerIndent;

  final double rowGap;

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
        grouped: w.rowDividers || w.rowCards,
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
                  for (final h in w.scrollHeader) ...[
                    h,
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ...(w.rowCards
                      ? cardedRows(w.children)
                      : w.rowDividers
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

  final PageController controller;

  final Widget Function(BuildContext context, T tab) pageBuilder;

  final List<Widget> header;
  final bool headerBelowTabs;

  final double topInset;

  final bool clearTopBar;

  final bool swipeEnabled;

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
