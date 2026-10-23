import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app/app_colors.dart';
import 'dashed_rect_border.dart';
import '../tokens/chip_size.dart';
import '../tokens/tone.dart';

enum AppChipTone {
  primary,

  neutral,
  warning,
  success,
  danger,
  info;

  static AppChipTone fromTone(Tone tone) => switch (tone) {
    Tone.neutral => AppChipTone.neutral,
    Tone.primary => AppChipTone.primary,
    Tone.success => AppChipTone.success,
    Tone.warning => AppChipTone.warning,
    Tone.danger => AppChipTone.danger,
    Tone.info => AppChipTone.info,
  };

  Color resolve(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      primary => scheme.primary,
      neutral => scheme.onSurfaceVariant,
      warning => palette.warning,
      success => palette.success,
      danger => palette.error,
      info => palette.info,
    };
  }
}

enum AppChipTrailing { none, dropdown, remove, count }

class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.icon,
    this.leading,
    this.dot = false,
    this.tone,
    this.color,
    this.selected = false,
    this.onTap,
    this.trailing = AppChipTrailing.none,
    this.onRemove,
    this.count = 0,
    ChipSize? size,
    this.enabled = true,
    this.tooltip,
    this.dashed = false,
    this.inset = false,
    this.removeOnly = false,
    this.maxWidth,
    this.fill,
    this.onFill,
    this.bold = false,
    this.bare = false,
    super.key,
  }) : assert(
         trailing != AppChipTrailing.remove || onRemove != null,
         'AppChipTrailing.remove needs onRemove',
       ),
       assert(
         trailing != AppChipTrailing.remove || size != ChipSize.mini,
         'a removable (✕) chip is not made in mini (20): too small to tap',
       ),
       _size = size;

  final String label;

  final IconData? icon;

  final Widget? leading;

  final bool dot;

  final AppChipTone? tone;

  final Color? color;

  final bool selected;

  final VoidCallback? onTap;

  final AppChipTrailing trailing;
  final VoidCallback? onRemove;

  final int count;

  final ChipSize? _size;
  final bool enabled;

  final String? tooltip;

  final bool dashed;

  final bool inset;

  final bool removeOnly;

  /// The chip never grows wider than this; the label ellipsises first.
  final double? maxWidth;

  final Color? fill;
  final Color? onFill;

  /// A bolder label for a chip that is the headline of its row (a hero's
  /// summary status).
  final bool bold;

  /// No fill, no border, no side padding: a bigger icon and the label in
  /// [color] (a wallet on a list row).
  final bool bare;

  static Color readableOn(Color bg, [Color? preferred]) {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance() + 0.05;
      final lb = b.computeLuminance() + 0.05;
      return la > lb ? la / lb : lb / la;
    }

    if (preferred != null && ratio(bg, preferred) >= 4.5) return preferred;
    final hsl = HSLColor.fromColor(bg);
    if (ratio(bg, Colors.white) >= 2.2) {
      var lo = hsl.lightness; // fails
      var hi = 1.0; // white: the most there is
      for (var i = 0; i < 12; i++) {
        final mid = (lo + hi) / 2;
        if (ratio(bg, hsl.withLightness(mid).toColor()) >= 4.5) {
          hi = mid; // passes: look for a shade closer to the fill
        } else {
          lo = mid;
        }
      }
      return hsl.withLightness(hi).toColor();
    }
    var lo = 0.0;
    var hi = hsl.lightness;
    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      if (ratio(bg, hsl.withLightness(mid).toColor()) >= 4.5) {
        lo = mid; // passes: look for a lighter shade, closer to the fill
      } else {
        hi = mid;
      }
    }
    return hsl.withLightness(lo).toColor();
  }

  static const double minTapHeight = 44;

  @override
  Widget build(BuildContext context) {
    final size = ChipSizeScope.resolve(context, _size);
    final height = size.heightOf(context);
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? (tone ?? AppChipTone.primary).resolve(context);
    final solid = bare ? null : fill;
    final fg = bare
        ? (color != null || tone != null ? tint : scheme.onSurfaceVariant)
        : solid != null
        ? readableOn(solid)
        : selected
        ? tint
        : scheme.onSurfaceVariant;
    final iconColor = bare
        ? fg
        : solid != null || color != null || tone != null
        ? (solid != null ? readableOn(solid, onFill) : tint)
        : fg;
    final iconSize = bare ? size.icon + 5 : size.icon;
    final gap = size.gap;
    final tap = enabled && !removeOnly
        ? (onTap ?? (trailing == AppChipTrailing.remove ? onRemove : null))
        : null;

    final Widget? lead = leading != null
        ? ConstrainedBox(
            constraints: BoxConstraints.tightFor(
              width: size.leading,
              height: size.leading,
            ),
            child: FittedBox(child: leading),
          )
        : icon != null
        ? Icon(icon, size: iconSize, color: iconColor)
        : null;

    final Widget? dotMark = dot
        ? Container(
            width: size.dot,
            height: size.dot,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          )
        : null;

    final Widget? tail = switch (trailing) {
      AppChipTrailing.none => null,
      AppChipTrailing.dropdown => Icon(
        AppIcons.dropdown,
        size: iconSize + 4,
        color: fg,
      ),
      AppChipTrailing.remove =>
        removeOnly
            ? InkResponse(
                onTap: enabled ? onRemove : null,
                radius: height / 2,
                child: SizedBox(
                  width: iconSize + 8,
                  height: height,
                  child: Center(
                    child: Icon(AppIcons.close, size: iconSize, color: fg),
                  ),
                ),
              )
            : onTap == null
            ? Icon(AppIcons.close, size: iconSize, color: fg)
            : InkResponse(
                onTap: enabled ? onRemove : null,
                radius: height / 2,
                child: Icon(AppIcons.close, size: iconSize, color: fg),
              ),
      AppChipTrailing.count =>
        count <= 0 ? null : _Count(count: count, color: fg, size: size),
    };

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: size
          .textStyle(context)
          ?.copyWith(
            color: fg,
            fontWeight: bold
                ? FontWeight.w700
                : bare
                ? FontWeight.w600
                : solid != null
                ? FontWeight.w500
                : ChipSize.chipWeight,
          ),
    );

    final iconOnly = label.isEmpty && lead != null && tail == null;
    final sidePad = bare
        ? 0.0
        : iconOnly
        ? (height - size.icon) / 2
        : size.padding;
    final borderColor = solid ?? (selected ? tint : scheme.outlineVariant);
    final ringed = dashed && inset && selected;
    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Padding(
        padding: EdgeInsets.only(
          left: sidePad,
          // ▾ / ✕ / 🔒 carry their own air; the filled count badge sits
          // concentric with the chip's round end instead.
          right: tail == null || iconOnly || bare
              ? sidePad
              : trailing == AppChipTrailing.count
              ? (height - (size.icon + 2)) / 2
              : removeOnly
              ? sidePad - AppSpacing.xs - 4
              : sidePad - AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lead != null) ...[lead, if (!iconOnly) SizedBox(width: gap)],
            if (dotMark != null) ...[dotMark, SizedBox(width: gap)],
            if (!iconOnly) Flexible(child: text),
            if (tail != null) ...[SizedBox(width: size.gap), tail],
          ],
        ),
      ),
    );
    Widget chip = Material(
      color:
          solid ??
          (selected ? tint.withValues(alpha: 0.12) : Colors.transparent),
      shape: StadiumBorder(
        side: dashed || bare
            ? BorderSide.none
            : BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: ringed
            ? Stack(
                children: [
                  content,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            shape: StadiumBorder(
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : content,
      ),
    );

    if (dashed) {
      chip = DashedRectBorder(
        color: borderColor,
        strokeWidth: selected && !ringed ? 1.5 : 1,
        dashLength: 4,
        gapLength: 3,
        borderRadius: Radius.circular(height / 2),
        child: chip,
      );
    }
    if (maxWidth != null) {
      chip = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: chip,
      );
    }

    Widget out = Semantics(
      button: tap != null,
      selected: selected,
      enabled: enabled,
      child: enabled ? chip : Opacity(opacity: 0.38, child: chip),
    );
    if (tooltip != null) {
      out = Tooltip(
        message: tooltip!,
        triggerMode: tap == null ? TooltipTriggerMode.tap : null,
        child: out,
      );
    }
    if (tap != null && height < minTapHeight) {
      out = _ExpandedHit(minHeight: minTapHeight, child: out);
    }
    return out;
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count, required this.color, required this.size});
  final int count;
  final Color color;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final h = size.icon + 2;
    return Container(
      constraints: BoxConstraints(minWidth: h, minHeight: h),
      padding: EdgeInsets.symmetric(horizontal: size.badgePad),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: size.badgeText,
          color: color,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _ExpandedHit extends SingleChildRenderObjectWidget {
  const _ExpandedHit({required this.minHeight, required super.child});

  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderExpandedHit(minHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderExpandedHit r) =>
      r.minHeight = minHeight;
}

class _RenderExpandedHit extends RenderProxyBox {
  _RenderExpandedHit(this.minHeight);

  double minHeight;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final extra = math.max(0.0, (minHeight - size.height) / 2);
    if (position.dx < 0 ||
        position.dx > size.width ||
        position.dy < -extra ||
        position.dy > size.height + extra) {
      return false;
    }
    final inside = Offset(position.dx, position.dy.clamp(0.0, size.height));
    if (child?.hitTest(result, position: inside) ?? false) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

class ChipSizeScope extends InheritedWidget {
  const ChipSizeScope({required this.size, required super.child, super.key})
    : force = false;

  /// Every chip inside takes [size], even one that sets its own (a row that
  /// must be one size, e.g. [HeroChipRow]).
  const ChipSizeScope.force({
    required this.size,
    required super.child,
    super.key,
  }) : force = true;

  final ChipSize size;
  final bool force;

  static ChipSize? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChipSizeScope>()?.size;

  /// The size a chip that asked for [own] gets here ([fallback] when neither
  /// it nor a scope says).
  static ChipSize resolve(
    BuildContext context,
    ChipSize? own, {
    ChipSize fallback = ChipSize.control,
  }) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChipSizeScope>();
    if (scope != null && scope.force) return scope.size;
    return own ?? scope?.size ?? fallback;
  }

  @override
  bool updateShouldNotify(ChipSizeScope old) =>
      size != old.size || force != old.force;
}
