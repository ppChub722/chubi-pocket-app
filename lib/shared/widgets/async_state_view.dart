import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../l10n/gen/app_localizations.dart';
import 'chips/tone.dart';
import 'error_view.dart';
import 'feedback/app_snackbar.dart';
import 'skeletons.dart';

/// One rule for every async-loaded screen (design-sheet §8.5) — pages only
/// say what "empty" looks like for them:
///
/// | nothing to show yet + | shows                                  |
/// |-----------------------|----------------------------------------|
/// | [loading]             | [skeleton]                             |
/// | [error]               | [ErrorView] + retry                    |
/// | neither               | [empty] (or [builder] when it's null)  |
///
/// With data on screen, [builder] always wins; a failed refresh then shows
/// a snackbar instead of hiding the data.
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

  final VoidCallback onRetry;

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
    if (!w.isEmpty) return w.builder(context);
    if (w.loading) {
      return w.skeleton ??
          ListView(
            children: [for (var i = 0; i < 6; i++) const SkeletonListTile()],
          );
    }
    if (w.error != null) {
      return ErrorView(error: w.error!, onRetry: w.onRetry);
    }
    return w.empty ?? w.builder(context);
  }
}
