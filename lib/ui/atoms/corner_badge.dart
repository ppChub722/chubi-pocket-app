import 'package:flutter/material.dart';

import '../tokens/avatar_metrics.dart';

/// A round badge on the bottom-right corner of an avatar / icon circle — the
/// edit pencil, the 🔗 link mark, a type glyph, a ✓ (owner 2026-10-12): a
/// filled circle with a glyph inside and a thin halo in the page colour, the
/// same look everywhere (it is the pencil of `EditableCircle`).
///
/// ```dart
/// CornerBadge(size: 40, icon: AppIcons.link, child: UserAvatar(…, size: 40))
/// ```
///
/// The badge scales with the avatar ([size], via [AvatarMetrics]) and is left
/// out below [AvatarMetrics.minCornerBadgeAvatar] (40): on a smaller avatar it
/// would cover a third of it. [essential] keeps a badge that carries state (a
/// ✓ that marks a row) on a smaller avatar too.
///
/// The footprint is always [size] × [size] — showing or hiding the badge never
/// reflows the layout.
class CornerBadge extends StatelessWidget {
  const CornerBadge({
    required this.child,
    required this.size,
    required this.icon,
    this.color,
    this.iconColor,
    this.tooltip,
    this.show = true,
    this.essential = false,
    super.key,
  });

  /// The avatar / icon circle.
  final Widget child;

  /// The avatar's diameter (what the badge scales with).
  final double size;
  final IconData icon;

  /// The badge fill; defaults to the theme's primary.
  final Color? color;

  /// The glyph colour; defaults to `onPrimary`.
  final Color? iconColor;
  final String? tooltip;

  /// false = no badge (e.g. an unmarked row); the footprint stays.
  final bool show;

  /// Show it even under the minimum avatar size (a state marker).
  final bool essential;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = show && (essential || AvatarMetrics.showsCornerBadge(size));
    final d = AvatarMetrics.cornerBadge(size);
    Widget badge = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: color ?? scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.surface,
          width: AvatarMetrics.frame(d).clamp(1.0, 2.0),
        ),
      ),
      child: Icon(
        icon,
        size: AvatarMetrics.cornerBadgeGlyph(d),
        color: iconColor ?? scheme.onPrimary,
      ),
    );
    if (tooltip != null) badge = Tooltip(message: tooltip!, child: badge);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (visible) Positioned(right: -2, bottom: -2, child: badge),
        ],
      ),
    );
  }
}
