import 'dart:async';

import 'package:flutter/material.dart';

import '../atoms/skeleton_box.dart';
import '../tokens/app_durations.dart';
import '../tokens/tone.dart';
import '../molecules/error_view.dart';
import '../molecules/app_snackbar.dart';
import 'pull_to_refresh.dart';
import '../atoms/connection_scope.dart';
import 'async_state_kind.dart';
import 'page_skeletons.dart';

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

  /// A detail page's body while its item isn't in the cache (when it is, the
  /// page renders its loaded Scaffold instead): skeleton → error + retry →
  /// [notFound].
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

  bool get _detail => identical(builder, _none);

  final bool loading;

  final Object? error;

  final bool isEmpty;

  final FutureOr<void> Function() onRetry;

  final WidgetBuilder builder;

  final Widget? empty;

  final Widget? skeleton;

  final bool snackOnRefreshError;

  final Duration? slowAfter;

  static const Duration defaultSlowAfter = Duration(seconds: 8);

  @override
  State<AsyncStateView> createState() => _AsyncStateViewState();
}

class _AsyncStateViewState extends State<AsyncStateView>
    with SingleTickerProviderStateMixin {
  bool _settled = false;

  /// The skeleton comes only after [AppMotion.duration] (owner 2026-11-12): a
  /// load that is quick (a cached page, a fast answer) never flashes it.
  Timer? _skeletonTimer;
  bool _skeletonDue = false;

  /// The skeleton that was showing when the content arrived: it stays over the
  /// content and fades out (the content is already in place under it), so the
  /// swap is a cross-fade, not a jump. [_fade] 1 = fully there.
  Widget? _leaving;
  Widget? _lastSkeleton;
  AsyncStateKind? _lastKind;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
  );
  late final CurvedAnimation _fadeCurve = CurvedAnimation(
    parent: _fade,
    curve: AppMotion.curve,
  );

  Timer? _slowTimer;

  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _syncSlowTimer();
    _syncSkeletonTimer();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _skeletonTimer?.cancel();
    _fadeCurve.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _syncSkeletonTimer() {
    if (!_firstLoading) {
      _skeletonTimer?.cancel();
      _skeletonTimer = null;
      _skeletonDue = false;
      return;
    }
    if (_skeletonDue) return;
    _skeletonTimer ??= Timer(AppMotion.duration, () {
      if (mounted) setState(() => _skeletonDue = true);
    });
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
    _syncSkeletonTimer();
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
    if (!w.loading || !w.isEmpty) _settled = true;
    final kind = asyncStateKind(
      loading: w.loading,
      isEmpty: w.isEmpty,
      hasError: w.error != null,
      hasEmptyView: w.empty != null,
      settled: _settled,
      slow: _slow,
      isOffline: () => ConnectionScope.isOffline(context),
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    // Content (or anything) arriving over a skeleton that was on screen: the
    // skeleton fades out over it.
    if (_lastKind == AsyncStateKind.skeleton &&
        kind != AsyncStateKind.skeleton &&
        _lastSkeleton != null &&
        !reduced) {
      _leaving = _lastSkeleton;
      _lastSkeleton = null;
      _fade.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fade.reverse().whenComplete(() {
          if (mounted) setState(() => _leaving = null);
        });
      });
    }
    _lastKind = kind;
    final view = switch (kind) {
      AsyncStateKind.content => w.builder(context),
      AsyncStateKind.offline => _pullable(
        ErrorView(error: TimeoutException('offline'), onRetry: _retry),
      ),
      AsyncStateKind.slow => _pullable(
        ErrorView(error: TimeoutException('still loading'), onRetry: _retry),
      ),
      AsyncStateKind.skeleton => _skeleton(w),
      AsyncStateKind.error => _pullable(
        ErrorView(error: w.error!, onRetry: w.onRetry),
      ),
      AsyncStateKind.empty => _pullable(w.empty!),
    };
    final leaving = _leaving;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        view,
        if (leaving != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(opacity: _fadeCurve, child: leaving),
            ),
          ),
      ],
    );
  }

  /// The skeleton, after the short wait, fading in; one shimmer for all of it.
  Widget _skeleton(AsyncStateView w) {
    if (!_skeletonDue) {
      _lastSkeleton = null;
      return const SizedBox.expand();
    }
    final skeleton = SkeletonShimmer(
      child:
          w.skeleton ??
          (w._detail
              ? const DetailPageSkeleton()
              : const ListPageSkeleton(rows: 6)),
    );
    _lastSkeleton = skeleton;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration,
      curve: AppMotion.curve,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: skeleton,
    );
  }

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
