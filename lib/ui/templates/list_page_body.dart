import 'package:flutter/material.dart';

import '../atoms/skeletons.dart';
import '../molecules/empty_view.dart';
import '../organisms/async_state_view.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';

/// The ListPage template's body (owner 2026-10-12): every list page is the same
/// skeleton —
///
///   [pinned header: search · filters · banners] → the list, with the first-load
///   skeleton, the full-page error + retry, the empty state, pull-to-refresh and
///   clearance for the floating bars.
///
/// The page keeps its own Scaffold / top bar / FAB / edit modes; this widget
/// is the content so loading, error, empty and refresh behave identically on
/// every list.
///
/// - [header]: widgets pinned above the list (a search bar, a `FilterBar`, a
///   `MessageBanner`) — they don't scroll.
/// - [children]: the list's rows (cards, rows, section headers) in order.
///   `ListView` padding is the page norm: [AppSpacing.lg] at the sides, [topInset]
///   above, [bottomInset] below (room for the centre + / a chat dial).
/// - [loading] / [error] / [isEmpty] / [onRetry]: the data state — see
///   `AsyncStateView`; [empty] is the empty view, [skeleton] overrides the
///   default skeleton rows.
class ListPageBody extends StatelessWidget {
  const ListPageBody({
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.empty,
    required this.children,
    this.header = const [],
    this.skeleton,
    this.topInset = AppSpacing.md,
    this.bottomInset = 96,
    this.sidePadding = AppSpacing.lg,
    super.key,
  });

  final bool loading;
  final Object? error;
  final bool isEmpty;
  final Future<void> Function() onRetry;
  final EmptyView empty;
  final List<Widget> children;
  final List<Widget> header;
  final Widget? skeleton;
  final double topInset;
  final double bottomInset;
  final double sidePadding;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.paddingOf(context);
    final padding = EdgeInsets.fromLTRB(
      sidePadding,
      topInset,
      sidePadding,
      bottomInset + mq.bottom,
    );
    final list = AsyncStateView(
      loading: loading,
      error: error,
      isEmpty: isEmpty,
      onRetry: onRetry,
      empty: empty,
      skeleton:
          skeleton ??
          ListView(
            padding: padding,
            children: [for (var i = 0; i < 6; i++) const SkeletonListTile()],
          ),
      builder: (context) => PullToRefresh(
        onRefresh: onRetry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: children,
        ),
      ),
    );
    if (header.isEmpty) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...header,
        Expanded(child: list),
      ],
    );
  }
}
