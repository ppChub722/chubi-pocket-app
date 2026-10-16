import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// The sliver delegate that pins a tab bar under the top bar once the hero
/// above it has scrolled away (the detail pages with tabs: events, wallets).
/// One piece instead of a hand-wired delegate per page:
///
/// ```dart
/// SliverPersistentHeader(
///   pinned: true,
///   delegate: PinnedTabBarDelegate(
///     background: Theme.of(context).scaffoldBackgroundColor,
///     child: PpForgeTabBar<…>(…),
///   ),
/// )
/// ```
class PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  PinnedTabBarDelegate({required this.background, required this.child});

  /// Behind the bar — the page colour, so content scrolls under it cleanly.
  final Color background;
  final Widget child;

  /// The pinned bar's height.
  static const double height = 52;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PpForgeSpacing.lg,
            PpForgeSpacing.sm,
            PpForgeSpacing.lg,
            0,
          ),
          child: child,
        ),
      );

  // The tab bar's selection lives in the page: always re-read it.
  @override
  bool shouldRebuild(PinnedTabBarDelegate old) => true;
}
