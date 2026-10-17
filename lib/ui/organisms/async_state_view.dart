import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/tone.dart';
import '../molecules/error_view.dart';
import '../molecules/app_snackbar.dart';
import 'pull_to_refresh.dart';
import '../atoms/connection_scope.dart';
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

class _AsyncStateViewState extends State<AsyncStateView> {
  bool _settled = false;

  Timer? _slowTimer;

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
    if (!w.loading || !w.isEmpty) _settled = true;
    if (!w.isEmpty) return w.builder(context);
    if (w.loading && !_settled && ConnectionScope.isOffline(context)) {
      return _pullable(
        ErrorView(error: TimeoutException('offline'), onRetry: _retry),
      );
    }
    if (w.loading && !_settled && _slow) {
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
