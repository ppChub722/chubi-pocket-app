import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'skeleton_box.dart';

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, borderRadius: 6);
  }
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, shape: BoxShape.circle);
  }
}

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

class SkeletonText extends StatelessWidget {
  const SkeletonText({required this.style, this.width, super.key});

  final TextStyle? Function(TextTheme theme) style;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final s = style(Theme.of(context).textTheme);
    final bar = ((s?.fontSize ?? 14) * 0.8).roundToDouble();
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Defines the line height; never visible.
        Text(' ', style: s, maxLines: 1),
        SkeletonLine(width: width, height: bar),
      ],
    );
  }
}
