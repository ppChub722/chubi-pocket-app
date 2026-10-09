import 'package:flutter/material.dart';

/// Standard pull-to-refresh wrapper used across every list page, so the
/// gesture + styling (spinner colour, trigger distance) stay identical
/// app-wide.
///
/// [child] must be a scrollable. For short lists that wouldn't otherwise
/// scroll, give it `physics: const AlwaysScrollableScrollPhysics()` so the
/// pull gesture still fires.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Called when the user pulls down. Resolve the future when the refresh
  /// completes — the spinner stays until then.
  final Future<void> Function() onRefresh;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: scheme.primary,
      backgroundColor: scheme.surfaceContainerHigh,
      // Pages float the top bar over their body (extendBodyBehindAppBar),
      // which folds the bar height into the top padding — start the
      // spinner below it instead of under the bar. 0 on pages without one.
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: child,
    );
  }
}
