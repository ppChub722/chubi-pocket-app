import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/gen/app_localizations.dart';
import 'chips/tone.dart';
import 'error_view.dart';
import 'feedback/app_snackbar.dart';
import 'pull_to_refresh.dart';
import 'skeletons.dart';

/// One rule for every async-loaded screen (design-sheet §8.5) — pages only
/// say what "empty" looks like for them:
///
/// | nothing to show yet + | shows                                  |
/// |-----------------------|----------------------------------------|
/// | first [loading]       | [skeleton]                             |
/// | [error]               | [ErrorView] + retry                    |
/// | neither               | [empty] (or [builder] when it's null)  |
///
/// With data on screen, [builder] always wins; a failed refresh then shows
/// a snackbar instead of hiding the data. Only the first load shows the
/// skeleton — reloading an empty page keeps the empty view. Error / empty
/// views are pull-to-refresh through [onRetry].
///
/// ```dart
/// AsyncStateView(
///   loading: state.status == BudgetsStatus.loading,
///   error: state.error,
///   isEmpty: state.budgets.isEmpty,
///   onRetry: cubit.load,
///   empty: EmptyView(...),
///   builder: (context) => ListView(...),
/// )
/// ```
///
/// Detail pages use [AsyncStateView.fallback] (not-found instead of empty).
class AsyncStateView extends StatefulWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.builder,
    this.empty,
    this.skeleton,
    this.snackOnRefreshError = true,
  });

  /// A detail page's body while its item isn't in the cache (when it is,
  /// the page renders its loaded Scaffold instead): skeleton → error +
  /// retry → [notFound].
  const AsyncStateView.fallback({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required Widget notFound,
    this.skeleton,
  }) : isEmpty = true,
       empty = notFound,
       builder = _none,
       snackOnRefreshError = false;

  static Widget _none(BuildContext _) => const SizedBox.shrink();

  /// A load is in flight (or hasn't started yet on first open).
  final bool loading;

  /// The last load's failure, null when it succeeded.
  final ApiException? error;

  /// Nothing to show — the list is empty / the item wasn't found.
  final bool isEmpty;

  /// Reloads. Backs the error view's retry button **and** pull-to-refresh
  /// on the error / empty / not-found views (owner 2026-10-09: empty pages
  /// refresh too). Return the load's future so the coin waits for it.
  final FutureOr<void> Function() onRetry;

  /// The content. Also used for the empty case when [empty] is null (pages
  /// whose empty state lives inside their own layout, e.g. under tabs).
  final WidgetBuilder builder;

  final Widget? empty;

  /// Defaults to a stack of [SkeletonListTile]s.
  final Widget? skeleton;

  /// Off when [builder] shows a failed refresh itself (home's banner).
  final bool snackOnRefreshError;

  @override
  State<AsyncStateView> createState() => _AsyncStateViewState();
}

class _AsyncStateViewState extends State<AsyncStateView> {
  /// A load has finished at least once. After that a reload (pull to
  /// refresh) keeps the current view instead of flashing the skeleton —
  /// it did on an empty page, whose "nothing to show" looked like a first
  /// load.
  bool _settled = false;

  @override
  void didUpdateWidget(AsyncStateView old) {
    super.didUpdateWidget(old);
    final e = widget.error;
    if (!widget.snackOnRefreshError ||
        e == null ||
        identical(e, old.error) ||
        widget.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      showAppSnackBar(context, ErrorView.titleFor(l, e), tone: Tone.danger);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    if (!w.loading) _settled = true;
    if (!w.isEmpty) return w.builder(context);
    if (w.loading && !_settled) {
      return w.skeleton ??
          ListView(
            children: [for (var i = 0; i < 6; i++) const SkeletonListTile()],
          );
    }
    if (w.error != null) {
      return _pullable(ErrorView(error: w.error!, onRetry: w.onRetry));
    }
    final empty = w.empty;
    return empty == null ? w.builder(context) : _pullable(empty);
  }

  /// A centred, non-scrolling view made pullable: scrollable at least the
  /// page's height (so the pull fires), refreshing through [onRetry].
  Widget _pullable(Widget view) {
    return PullToRefresh(
      onRefresh: () async => widget.onRetry(),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: view,
          ),
        ),
      ),
    );
  }
}
