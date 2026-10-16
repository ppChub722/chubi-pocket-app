import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../tokens/color_contrast.dart';

/// How a hero looks — ONE object, so the hero card and its one-line stand-in
/// ([CompactHeroBar]) can never drift (owner 2026-10-12):
///
/// - [HeroStyle.plain] — an ordinary bordered card (no entity colour);
/// - [HeroStyle.tinted] — the entity colour as a soft wash from the top-left, a
///   border in that colour and, optionally, a faint [glyph] watermark in the
///   corner (every entity's hero; the wallet's own card is the same style with
///   a lighter border).
///
/// Build it once where the hero is built (e.g. `HeroStyle.tinted(color:
/// category colour, glyph: PpForgeIcons.category)`) and hand it to the hero card
/// AND to its compact bar.
@immutable
class HeroStyle {
  const HeroStyle.plain()
    : color = null,
      glyph = null,
      borderColor = null,
      borderWidth = null;

  /// [strongBorder]: a 1.5 border in the colour (heroes); false = the soft
  /// 25 % border (the wallet card). [borderColor] overrides the border colour
  /// (a transfer's neutral outline).
  const HeroStyle.tinted({
    required Color this.color,
    this.glyph,
    bool strongBorder = true,
    this.borderColor,
  }) : borderWidth = strongBorder ? 1.5 : null;

  /// The entity colour; null = plain.
  final Color? color;

  /// The faint corner watermark.
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

/// The surface of a hero for a [HeroStyle]: an [PpForgeCard] in the style's
/// look. Used by the hero card and by the compact bar (which passes a pill
/// [radius] and a smaller [glyphSize]).
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
      return PpForgeCard(
        style: PpForgeCardStyle.bordered,
        onTap: onTap,
        radius: radius,
        margin: margin,
        child: child,
      );
    }
    return PpForgeCard(
      style: PpForgeCardStyle.tinted,
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
