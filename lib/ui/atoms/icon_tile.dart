import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/avatar_metrics.dart';
import 'corner_badge.dart';

enum IconTileShape { circle, rounded }

enum IconTileStyle { soft, solid }

class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.color,
    this.size = 36,
    this.shape = IconTileShape.circle,
    this.style = IconTileStyle.soft,
    this.badgeIcon,
    this.glyphSize,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// The glyph's size; default the avatar metric for [size].
  final double? glyphSize;
  final IconTileShape shape;
  final IconTileStyle style;

  final IconData? badgeIcon;

  static const gap = SizedBox(height: AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    final solid = style == IconTileStyle.solid;
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.18),
        shape: shape == IconTileShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == IconTileShape.circle
            ? null
            : BorderRadius.circular(size >= 40 ? AppRadius.md : AppRadius.sm),
      ),
      child: Icon(
        icon,
        size: glyphSize ?? AvatarMetrics.glyph(size),
        color: solid ? Colors.white : color,
      ),
    );
    if (badgeIcon == null) return tile;
    return CornerBadge(size: size, icon: badgeIcon!, child: tile);
  }
}
