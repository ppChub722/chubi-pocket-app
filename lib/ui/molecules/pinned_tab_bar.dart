import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

class PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  PinnedTabBarDelegate({required this.background, required this.child});

  final Color background;
  final Widget child;

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
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: child,
        ),
      );

  @override
  bool shouldRebuild(PinnedTabBarDelegate old) => true;
}
