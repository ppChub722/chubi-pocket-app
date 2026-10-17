import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../tokens/color_contrast.dart';

@immutable
class HeroStyle {
  const HeroStyle.plain()
    : color = null,
      glyph = null,
      borderColor = null,
      borderWidth = null;

  const HeroStyle.tinted({
    required Color this.color,
    this.glyph,
    bool strongBorder = true,
    this.borderColor,
  }) : borderWidth = strongBorder ? 1.5 : null;

  final Color? color;

  final IconData? glyph;
  final Color? borderColor;
  final double? borderWidth;

  bool get tinted => color != null;

  @override
  bool operator ==(Object other) =>
      other is HeroStyle &&
      other.color == color &&
      other.glyph == glyph &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth;

  @override
  int get hashCode => Object.hash(color, glyph, borderColor, borderWidth);
}

class HeroSurface extends StatelessWidget {
  const HeroSurface({
    required this.style,
    required this.child,
    this.onTap,
    this.radius,
    this.glyphSize = 120,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final HeroStyle style;
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final double glyphSize;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final color = style.color;
    if (color == null) {
      return AppCard(
        style: AppCardStyle.bordered,
        onTap: onTap,
        radius: radius,
        margin: margin,
        child: child,
      );
    }
    return AppCard(
      style: AppCardStyle.tinted,
      color: color,
      glyph: style.glyph,
      glyphSize: glyphSize,
      borderColor:
          style.borderColor ??
          (style.borderWidth != null
              ? ensureContrast(color, Theme.of(context).colorScheme.surface)
              : null),
      borderWidth: style.borderWidth,
      onTap: onTap,
      radius: radius,
      margin: margin,
      child: child,
    );
  }
}
