import 'package:flutter/material.dart';

import '../tokens/avatar_metrics.dart';

/// A small round badge on the bottom-right corner of an avatar or icon: an
/// [icon] glyph on a filled disc, or a [glyph] widget (a brand logo image)
/// filling the disc.
class CornerBadge extends StatelessWidget {
  const CornerBadge({
    required this.child,
    required this.size,
    this.icon,
    this.glyph,
    this.color,
    this.iconColor,
    this.tooltip,
    this.show = true,
    this.essential = false,
    this.scale = 1,
    this.glyphRatio,
    this.hug = false,
    super.key,
  }) : assert(icon != null || glyph != null, 'an icon or a glyph');

  /// Grows the badge past the metric size (a person's 🔗 is a bit bigger).
  final double scale;

  /// The glyph's share of the badge; default the metric one (0.62).
  final double? glyphRatio;

  final Widget child;

  final double size;
  final IconData? icon;

  /// In place of [icon]: a widget clipped to the disc and filling it (a
  /// brand logo). The disc colour shows behind a transparent image.
  final Widget? glyph;

  final Color? color;

  final Color? iconColor;
  final String? tooltip;

  final bool show;

  final bool essential;

  /// Take the child's own size and only overlay its corner (a row's
  /// leading: with or without a badge it sits and measures the same). False
  /// = a [size] square the child fills.
  final bool hug;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = show && (essential || AvatarMetrics.showsCornerBadge(size));
    final d = AvatarMetrics.cornerBadge(size) * scale;
    final glyph = this.glyph;
    Widget badge = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: color ?? (glyph == null ? scheme.primary : scheme.surface),
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.surface,
          width: AvatarMetrics.frame(d).clamp(1.0, 2.0),
        ),
      ),
      child: glyph != null
          ? ClipOval(child: SizedBox.expand(child: glyph))
          : Icon(
              icon,
              size: glyphRatio == null
                  ? AvatarMetrics.cornerBadgeGlyph(d)
                  : d * glyphRatio!,
              color: iconColor ?? scheme.onPrimary,
            ),
    );
    if (tooltip != null) badge = Tooltip(message: tooltip!, child: badge);
    final corner = Positioned(right: -2, bottom: -2, child: badge);
    if (hug) {
      return Stack(
        clipBehavior: Clip.none,
        children: [child, if (visible) corner],
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (visible) corner,
        ],
      ),
    );
  }
}
