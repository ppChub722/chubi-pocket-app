import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/avatar_metrics.dart';
import 'corner_badge.dart';

/// The outline of an [IconTile].
enum IconTileShape {
  /// A circle — list-row glyphs.
  circle,

  /// A rounded square (radius 12 from 40 px up, 8 below) — the head of a card.
  rounded,
}

/// How an [IconTile] is filled.
enum IconTileStyle {
  /// An 18 % wash of the colour with a glyph in the colour — quiet, for rows.
  soft,

  /// The solid colour with a white glyph — loud, for the head of a tinted card.
  solid,
}

/// The one icon tile (owner 2026-10-12): a glyph in a coloured shape. It
/// replaces the old `IconBubble` (circle · soft) and `TintedIconBadge`
/// (rounded · solid), which differed only by these two parameters.
///
/// ```dart
/// IconTile(icon: AppIcons.expense, color: c)                  // row glyph
/// IconTile(icon: AppIcons.budget, color: c,
///          shape: IconTileShape.rounded, style: IconTileStyle.solid,
///          size: 40)                                          // card head
/// ```
///
/// The glyph scales with the tile ([AvatarMetrics.glyph]). [badgeIcon] adds a
/// [CornerBadge] (left out below 40 px).
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.color,
    this.size = 36,
    this.shape = IconTileShape.circle,
    this.style = IconTileStyle.soft,
    this.badgeIcon,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final IconTileShape shape;
  final IconTileStyle style;

  /// A corner badge glyph (e.g. the notification type over an avatar).
  final IconData? badgeIcon;

  /// Gap under a tile before the card's title.
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
      // Module / accent colours are saturated — white reads on all of them.
      child: Icon(
        icon,
        size: AvatarMetrics.glyph(size),
        color: solid ? Colors.white : color,
      ),
    );
    if (badgeIcon == null) return tile;
    return CornerBadge(size: size, icon: badgeIcon!, child: tile);
  }
}
