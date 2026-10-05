import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'skeleton_box.dart';

/// Composable skeleton primitives built on [SkeletonBox]. Pages compose
/// these into a page-specific skeleton (co-located with the page) that
/// mirrors the real content shape, then pass it to
/// `LoadingView(skeleton: ...)`. Per design-sheet §8.5 — no spinners on
/// lists.

/// A single shimmer text line.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: 6);
  }
}

/// A shimmer circle — avatar / icon placeholder.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, shape: BoxShape.circle);
  }
}

/// A list-row skeleton: leading circle + one or two text lines. [indent]
/// shifts the whole row right (for tree-style lists).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    this.avatarSize = 40,
    this.lines = 2,
    this.indent = 0,
    super.key,
  });

  final double avatarSize;
  final int lines;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg + indent,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: avatarSize),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLine(width: 150),
                if (lines > 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const SkeletonLine(width: 90, height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
