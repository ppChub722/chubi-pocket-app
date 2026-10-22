import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'app_tab_bar.dart';

/// Pins an [AppTabBar] under the top bar once the hero scrolls away.
class PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  PinnedTabBarDelegate({required this.background, required this.child});

  final Color background;
  final Widget child;

  /// The bar plus a small gap above and below.
  static const double height = AppSpacing.sm + AppTabBar.height + AppSpacing.sm;

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
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: child,
        ),
      );

  @override
  bool shouldRebuild(PinnedTabBarDelegate old) => true;
}
