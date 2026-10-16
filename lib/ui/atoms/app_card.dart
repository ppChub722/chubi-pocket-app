import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/color_contrast.dart';

/// How an [PpForgeCard] looks.
enum PpForgeCardStyle {
  /// The theme's card: surface fill, soft outline. Lists, summaries.
  plain,

  /// A raised surface with a normal outline — a card inside a card, picker
  /// cards, a row-sized "thing".
  bordered,

  /// A raised surface with a 1.5 border in a colour — the icon preview card
  /// (heroes are [tinted]).
  accent,

  /// Washed in one colour: a soft gradient from the top-left, a border in the
  /// same tint and an optional big faded glyph in the corner — "this is a
  /// thing of colour X" (wallet cards, the เพิ่มเติม hub, dashboard tiles).
  tinted,

  /// No fill, no border, no elevation — only the rounded clip and the ripple
  /// (an empty "nothing picked yet" slot drawn inside a dashed outline).
  flat,
}

/// The one card — every surface in the app (owner 2026-10-12). Features never
/// build their own `Card` / `Material(shape:)` / `DecoratedBox`; pick a
/// [style].
///
/// ```dart
/// PpForgeCard(child: …)                                   // plain list card
/// PpForgeCard(style: PpForgeCardStyle.accent, color: c, …)    // coloured border
/// PpForgeCard(style: PpForgeCardStyle.tinted, color: c, glyph: PpForgeIcons.budget, …)
/// ```
///
/// - [color] = the border colour of [PpForgeCardStyle.accent] / the wash of
///   [PpForgeCardStyle.tinted]; ignored by the other styles.
/// - [onTap] adds the ripple; the card clips its child to the corners.
/// - [margin] defaults to none (the page's gaps place cards); [padding]
///   defaults to none (rows / heroes bring their own).
/// - [borderColor] overrides the border of any style (a warning / error
///   outline, e.g. an overdue row).
/// - [selected] draws the 1.5 primary border of a picked card.
class PpForgeCard extends StatelessWidget {
  const PpForgeCard({
    required this.child,
    this.style = PpForgeCardStyle.plain,
    this.color,
    this.glyph,
    this.glyphSize = 88,
    this.borderColor,
    this.borderWidth,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.radius,
    super.key,
  }) : assert(
         style != PpForgeCardStyle.tinted && style != PpForgeCardStyle.accent ||
             color != null,
         'accent and tinted cards need a color',
       );

  final Widget child;
  final PpForgeCardStyle style;

  /// The accent border / the tint wash colour.
  final Color? color;

  /// Tinted only: the faded corner watermark.
  final IconData? glyph;
  final double glyphSize;

  /// Overrides the style's border colour / width.
  final Color? borderColor;
  final double? borderWidth;

  /// A picked card: a 1.5 primary border.
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;

  /// Corner radius; null = [PpForgeRadius.lg] (a pill-shaped bar passes its own).
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).cardTheme;
    // Tint colours come from user icons (can be pale): the border and glyph are
    // clamped to >= 3:1 against the surface so they always read.
    final tint = color == null ? null : ensureContrast(color!, scheme.surface);

    final Color? fill = switch (style) {
      PpForgeCardStyle.plain => null,
      PpForgeCardStyle.bordered ||
      PpForgeCardStyle.accent => scheme.surfaceContainer,
      PpForgeCardStyle.tinted => null,
      PpForgeCardStyle.flat => Colors.transparent,
    };
    var border =
        borderColor ??
        switch (style) {
          PpForgeCardStyle.plain =>
            (theme.shape is RoundedRectangleBorder
                    ? (theme.shape! as RoundedRectangleBorder).side.color
                    : null) ??
                scheme.outlineVariant,
          PpForgeCardStyle.bordered => scheme.outlineVariant,
          PpForgeCardStyle.accent => tint!,
          PpForgeCardStyle.tinted => tint!.withValues(alpha: 0.25),
          PpForgeCardStyle.flat => Colors.transparent,
        };
    var width =
        borderWidth ??
        switch (style) {
          PpForgeCardStyle.accent => 1.5,
          _ => 1.0,
        };
    if (selected) {
      border = scheme.primary;
      width = 1.5;
    }

    Widget body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (style == PpForgeCardStyle.tinted && glyph != null) {
      body = Stack(
        children: [
          Positioned(
            right: -glyphSize * 0.16,
            bottom: -glyphSize * 0.2,
            child: Icon(
              glyph,
              size: glyphSize,
              color: tint!.withValues(alpha: 0.10),
            ),
          ),
          body,
        ],
      );
    }
    if (onTap != null || onLongPress != null) {
      body = InkWell(onTap: onTap, onLongPress: onLongPress, child: body);
    }
    if (style == PpForgeCardStyle.tinted) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint!.withValues(alpha: 0.16),
              tint.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: body,
      );
    }

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: style == PpForgeCardStyle.flat ? 0 : null,
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.circular(PpForgeRadius.lg),
        side: BorderSide(color: border, width: width),
      ),
      child: body,
    );
  }
}
