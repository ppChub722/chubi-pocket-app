import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/color_contrast.dart';

enum AppCardStyle { plain, bordered, accent, tinted, flat }

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

  final Color? color;

  final IconData? glyph;
  final double glyphSize;

  final Color? borderColor;
  final double? borderWidth;

  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;

  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).cardTheme;
    final tint = color == null ? null : ensureContrast(color!, scheme.surface);

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
          AppCardStyle.accent => tint!,
          AppCardStyle.tinted => tint!.withValues(alpha: 0.25),
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
      // passthrough: a card given a fixed height keeps its content laid out in
      // that height (centred by the child), glyph or not.
      body = Stack(
        fit: StackFit.passthrough,
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
    if (style == AppCardStyle.tinted) {
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
