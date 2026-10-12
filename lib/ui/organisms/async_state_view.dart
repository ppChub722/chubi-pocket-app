import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import '../molecules/error_view.dart';
import '../molecules/app_snackbar.dart';
import 'pull_to_refresh.dart';
import '../atoms/connection_scope.dart';
import 'page_skeletons.dart';

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
    this.slowAfter = defaultSlowAfter,
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
    this.slowAfter = defaultSlowAfter,
  }) : isEmpty = true,
       empty = notFound,
       builder = _none,
       snackOnRefreshError = false;

  static Widget _none(BuildContext _) => const SizedBox.shrink();

  /// Built by [AsyncStateView.fallback] (a detail page).
  bool get _detail => identical(builder, _none);

  /// A load is in flight (or hasn't started yet on first open).
  final bool loading;

  /// The last load's failure, null when it succeeded.
  final Object? error;

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

  /// How long the FIRST load may sit on the skeleton before the page offers
  /// "retry" (a [TimeoutException] error view) — the safety net for a load that
  /// never resolves or whose failure the page didn't catch. The load keeps
  /// running: if it finishes, the content appears. Null = never.
  final Duration? slowAfter;

  /// Matches the 5 s connect / 10 s receive timeouts of page-load GETs plus slack.
  static const Duration defaultSlowAfter = Duration(seconds: 8);

  @override
  State<AsyncStateView> createState() => _AsyncStateViewState();
}

class _AsyncStateViewState extends State<AsyncStateView> {
  /// A load has finished at least once. After that a reload (pull to
  /// refresh) keeps the current view instead of flashing the skeleton —
  /// it did on an empty page, whose "nothing to show" looked like a first
  /// load.
  bool _settled = false;

  Timer? _slowTimer;

  /// The first load has outlasted [AsyncStateView.slowAfter].
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _syncSlowTimer();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  bool get _firstLoading => widget.loading && widget.isEmpty && !_settled;

  void _syncSlowTimer() {
    final after = widget.slowAfter;
    if (!_firstLoading || after == null) {
      _slowTimer?.cancel();
      _slowTimer = null;
      _slow = false;
      return;
    }
    _slowTimer ??= Timer(after, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  void _retry() {
    _slowTimer?.cancel();
    _slowTimer = null;
    setState(() => _slow = false);
    widget.onRetry();
    _syncSlowTimer();
  }

  @override
  void didUpdateWidget(AsyncStateView old) {
    super.didUpdateWidget(old);
    _syncSlowTimer();
    final e = widget.error;
    if (!widget.snackOnRefreshError ||
        e == null ||
        identical(e, old.error) ||
        widget.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        ErrorView.titleFor(context, e),
        tone: Tone.danger,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    // The skeleton is for the FIRST load only (owner 2026-10-12): once a load has
    // finished OR data has been on screen, a reload — a pull to refresh, a filter
    // change — never swaps the content for the skeleton.
    if (!w.loading || !w.isEmpty) _settled = true;
    if (!w.isEmpty) return w.builder(context);
    // Offline (the app knows the server is unreachable): a page with no data shows
    // the full-page error + retry AT ONCE — no skeleton wait. Pages with data stay.
    if (w.loading && !_settled && ConnectionScope.isOffline(context)) {
      return _pullable(
        ErrorView(error: TimeoutException('offline'), onRetry: _retry),
      );
    }
    if (w.loading && !_settled && _slow) {
      // Still on the first load after [slowAfter]: offer retry (the load goes on).
      return _pullable(
        ErrorView(error: TimeoutException('still loading'), onRetry: _retry),
      );
    }
    if (w.loading && !_settled) {
      return w.skeleton ??
          (w._detail
              ? const DetailPageSkeleton()
              : const ListPageSkeleton(rows: 6));
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
