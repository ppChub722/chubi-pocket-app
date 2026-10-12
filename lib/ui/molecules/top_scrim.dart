import 'package:flutter/material.dart';

/// The top SCRIM (owner 2026-10-12): bodies run behind the transparent top bar
/// (`extendBodyBehindAppBar`), so scrolled content would show under the clock
/// and behind the floating pills. This gradient is pinned over the body: the
/// page background, solid across the status-bar [inset], fading to transparent
/// over the [barHeight] — the pills still read as floating.
///
/// Ignores pointers (the content below the fade stays tappable / scrollable),
/// takes the size its parent gives it and changes no layout. Used by
/// `AppTopBar` (as its flexible space); the hub shows it on a scrolled page.
class TopScrim extends StatelessWidget {
  const TopScrim({
    required this.inset,
    this.barHeight = kToolbarHeight,
    this.color,
    super.key,
  });

  /// The status-bar inset (`MediaQuery.paddingOf(context).top`).
  final double inset;

  /// The bar's own height under the inset.
  final double barHeight;

  /// The page colour; null = the theme's scaffold background.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).scaffoldBackgroundColor;
    final solid = inset <= 0 ? 0.0 : inset / (inset + barHeight);
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg, bg, bg.withValues(alpha: 0)],
              stops: [0, solid, 1],
            ),
          ),
        ),
      ),
    );
  }
}
