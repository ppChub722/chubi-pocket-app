import 'package:flutter/material.dart';

import 'busy_scope.dart';
import '../tokens/app_radius.dart';
import '../tokens/color_contrast.dart';
import 'dashed_rect_border.dart';

enum PpForgeCardStyle { plain, bordered, accent, tinted, flat }

/// Tells the [PpForgeCard]s below it that they are options of a picker: the chosen
/// one gets one solid line, the others a dashed one.
class PpForgeCardPick extends InheritedWidget {
  const PpForgeCardPick({required this.chosen, required super.child, super.key});

  final bool chosen;

  static PpForgeCardPick? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PpForgeCardPick>();

  @override
  bool updateShouldNotify(PpForgeCardPick old) => chosen != old.chosen;
}

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

  // Faded and inert under a locked [BusyScope] (a save runs elsewhere).
  @override
  Widget build(BuildContext context) => BusyLock(
    locked:
        (onTap != null || onLongPress != null) && BusyScope.isLocked(context),
    child: _build(context),
  );

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).cardTheme;
    final tint = color == null ? null : ensureContrast(color!, scheme.surface);

    final Color? fill = switch (style) {
      PpForgeCardStyle.plain => null,
      PpForgeCardStyle.bordered || PpForgeCardStyle.accent => scheme.surfaceContainer,
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
    final pick = PpForgeCardPick.maybeOf(context);
    final dashed = pick != null && !pick.chosen;
    if (selected || (pick?.chosen ?? false)) {
      border = scheme.primary;
      width = 1.5;
    } else if (dashed) {
      border = Colors.transparent;
    }

    Widget body = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    if (style == PpForgeCardStyle.tinted && glyph != null) {
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

    final corners = radius ?? BorderRadius.circular(PpForgeRadius.lg);
    final card = Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: style == PpForgeCardStyle.flat ? 0 : null,
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: corners,
        side: BorderSide(color: border, width: width),
      ),
      child: body,
    );
    if (!dashed) return card;
    return DashedRectBorder(
      color: scheme.outlineVariant,
      strokeWidth: 1,
      dashLength: 4,
      gapLength: 3,
      borderRadius: corners.topLeft,
      child: card,
    );
  }
}
