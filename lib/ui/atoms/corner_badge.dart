import 'package:flutter/material.dart';

import '../tokens/avatar_metrics.dart';

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

  final Widget child;

  final double size;
  final IconData icon;

  final Color? color;

  final Color? iconColor;
  final String? tooltip;

  final bool show;

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
