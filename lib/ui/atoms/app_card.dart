import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';

/// How an [AppCard] looks.
enum AppCardStyle {
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
/// AppCard(child: …)                                   // plain list card
/// AppCard(style: AppCardStyle.accent, color: c, …)    // coloured border
/// AppCard(style: AppCardStyle.tinted, color: c, glyph: AppIcons.budget, …)
/// ```
///
/// - [color] = the border colour of [AppCardStyle.accent] / the wash of
///   [AppCardStyle.tinted]; ignored by the other styles.
/// - [onTap] adds the ripple; the card clips its child to the corners.
/// - [margin] defaults to none (the page's gaps place cards); [padding]
///   defaults to none (rows / heroes bring their own).
/// - [borderColor] overrides the border of any style (a warning / error
///   outline, e.g. an overdue row).
/// - [selected] draws the 1.5 primary border of a picked card.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.style = AppCardStyle.plain,
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
         style != AppCardStyle.tinted && style != AppCardStyle.accent ||
             color != null,
         'accent and tinted cards need a color',
       );

  final Widget child;
  final AppCardStyle style;

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

  /// Corner radius; null = [AppRadius.lg] (a pill-shaped bar passes its own).
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).cardTheme;

    final Color? fill = switch (style) {
      AppCardStyle.plain => null,
      AppCardStyle.bordered || AppCardStyle.accent => scheme.surfaceContainer,
      AppCardStyle.tinted => null,
      AppCardStyle.flat => Colors.transparent,
    };
    var border =
        borderColor ??
        switch (style) {
          AppCardStyle.plain =>
            (theme.shape is RoundedRectangleBorder
                    ? (theme.shape! as RoundedRectangleBorder).side.color
                    : null) ??
                scheme.outlineVariant,
          AppCardStyle.bordered => scheme.outlineVariant,
          AppCardStyle.accent => color!,
          AppCardStyle.tinted => color!.withValues(alpha: 0.25),
          AppCardStyle.flat => Colors.transparent,
        };
    var width =
        borderWidth ??
        switch (style) {
          AppCardStyle.accent => 1.5,
          _ => 1.0,
        };
    if (selected) {
      border = scheme.primary;
      width = 1.5;
    }

    Widget body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (style == AppCardStyle.tinted && glyph != null) {
      body = Stack(
        children: [
          Positioned(
            right: -glyphSize * 0.16,
            bottom: -glyphSize * 0.2,
            child: Icon(
              glyph,
              size: glyphSize,
              color: color!.withValues(alpha: 0.10),
            ),
          ),
          body,
        ],
      );
    }
    if (onTap != null || onLongPress != null) {
      body = InkWell(onTap: onTap, onLongPress: onLongPress, child: body);
    }
    if (style == AppCardStyle.tinted) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color!.withValues(alpha: 0.16),
              color!.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: body,
      );
    }

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: style == AppCardStyle.flat ? 0 : null,
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: border, width: width),
      ),
      child: body,
    );
  }
}
