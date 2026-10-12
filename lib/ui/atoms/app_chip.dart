import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app/app_colors.dart';
import 'dashed_rect_border.dart';
import '../tokens/chip_size.dart';
import '../tokens/tone.dart';

/// [AppChip]'s colour, by meaning. [color] on the chip overrides it with
/// any colour (a category's, a tag's, a wallet's accent).
enum AppChipTone {
  primary,

  /// Grey even when selected — a quiet label ("ผ่อน", "แบบเกิดซ้ำ").
  neutral,
  warning,
  success,
  danger,
  info;

  /// The status [Tone]s (a project's, a debt's, a member's) as chip tones.
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

/// What sits after an [AppChip]'s label.
enum AppChipTrailing {
  none,

  /// ▾ — the chip opens a menu / sheet.
  dropdown,

  /// ✕ — drops it ([AppChip.onRemove]).
  remove,

  /// 🔒 — can't be changed (a saved row's type).
  lock,

  /// A small counter ([AppChip.count]) — how many are picked.
  count,
}

/// The one chip of the app (owner 2026-10-11) — every label, status, tag,
/// filter, choice and action. A stadium; unselected = a grey outline with
/// grey text (a custom [tone] / [color] still tints the icon), selected = a
/// border and a faint fill in its colour.
///
///   [● | icon | avatar]  label  [▾ | ✕ | 🔒 | n]
///
/// - **Interactive:** [onTap] + [selected]. A display chip (a status, a
///   type, a tag on a detail page) has no [onTap] and usually
///   `selected: true`, so it wears its colour. A not-yet-chosen pick is
///   [dashed].
/// - **Size** ([ChipSize]): [ChipSize.control] 40 (the default — what the user
///   operates, and a hero's top row), [ChipSize.chip] 28 (display chips in
///   cards and rows), [ChipSize.mini] 20 (dense list rows) — everything (icon,
///   text, padding, gap, avatar, count badge) scales with it. The height is
///   the size's, whatever the content.
/// - **Disabled:** [enabled] false fades it and ignores taps.
///
/// Not chips: [AppBadge] (a counter label) and the period steppers.
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
    this.maxWidth,
    super.key,
  }) : assert(
         trailing != AppChipTrailing.remove || onRemove != null,
         'AppChipTrailing.remove needs onRemove',
       ),
       _size = size;

  final String label;

  /// Before the label, in the chip's colour.
  final IconData? icon;

  /// Replaces [icon] with a widget (an avatar), fitted to the chip.
  final Widget? leading;

  /// A status dot before the label (after [icon] / [leading] if both).
  final bool dot;

  /// The chip's colour by meaning — null = primary (the icon then follows
  /// the text: grey until selected).
  final AppChipTone? tone;

  /// Any colour — overrides [tone].
  final Color? color;

  final bool selected;

  /// Null = display-only (no ink). With [AppChipTrailing.remove] and no
  /// [onTap], tapping anywhere removes.
  final VoidCallback? onTap;

  final AppChipTrailing trailing;
  final VoidCallback? onRemove;

  /// For [AppChipTrailing.count].
  final int count;

  /// [ChipSize.control] (default), [ChipSize.chip] or [ChipSize.mini]; null =
  /// the enclosing [ChipSizeScope]'s, else control.
  final ChipSize? _size;
  final bool enabled;

  /// A tap-to-read hint (why it's locked, what ✕ drops).
  final String? tooltip;

  /// A dashed outline instead of a solid one — "nothing picked yet, tap to
  /// pick" (the pending form's `เลือกกระเป๋า` / `เลือกหมวด`).
  final bool dashed;

  /// The chip never grows wider than this; the label ellipsises first.
  final double? maxWidth;

  /// An interactive chip answers a tap this far above and below itself when
  /// it is shorter than this (an invisible target — the layout is
  /// untouched). Needs room around the chip: a parent that clips taps to its
  /// own box (a chip row with no padding) still caps it.
  static const double minTapHeight = 44;

  @override
  Widget build(BuildContext context) {
    final size = _size ?? ChipSizeScope.of(context) ?? ChipSize.control;
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? (tone ?? AppChipTone.primary).resolve(context);
    final fg = selected ? tint : scheme.onSurfaceVariant;
    // A chosen colour shows on the icon even unselected (a category's icon);
    // the default primary doesn't.
    final iconColor = color != null || tone != null ? tint : fg;
    final iconSize = size.icon;
    final gap = size.gap;
    final tap = enabled
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
      AppChipTrailing.lock => Icon(
        AppIcons.lock,
        size: iconSize - 2,
        color: fg,
      ),
      AppChipTrailing.remove =>
        // Its own target when the chip does something else on tap.
        onTap == null
            ? Icon(AppIcons.close, size: iconSize, color: fg)
            : InkResponse(
                onTap: enabled ? onRemove : null,
                radius: size.height / 2,
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
          ?.copyWith(color: fg, fontWeight: ChipSize.chipWeight),
    );

    final sidePad = size.padding;
    final borderColor = selected ? tint : scheme.outlineVariant;
    Widget chip = Material(
      color: selected ? tint.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(
        side: dashed
            ? BorderSide.none
            : BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Padding(
            padding: EdgeInsets.only(
              left: sidePad,
              // ▾ / ✕ / 🔒 carry their own air; the filled count badge sits
              // concentric with the chip's round end instead.
              right: tail == null
                  ? sidePad
                  : trailing == AppChipTrailing.count
                  ? (size.height - (size.icon + 2)) / 2
                  : sidePad - AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lead != null) ...[lead, SizedBox(width: gap)],
                if (dotMark != null) ...[dotMark, SizedBox(width: gap)],
                Flexible(child: text),
                if (tail != null) ...[SizedBox(width: size.gap), tail],
              ],
            ),
          ),
        ),
      ),
    );

    if (dashed) {
      chip = DashedRectBorder(
        color: borderColor,
        strokeWidth: selected ? 1.5 : 1,
        dashLength: 4,
        gapLength: 3,
        borderRadius: Radius.circular(size.height / 2),
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
    // Outermost: the wrappers above gate hit tests to their own boxes.
    if (tap != null && size.height < minTapHeight) {
      out = _ExpandedHit(minHeight: minTapHeight, child: out);
    }
    return out;
  }
}

/// [AppChipTrailing.count]: the number on a faint stadium of [color].
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

/// Lets a short interactive child answer taps up to [minHeight] tall without
/// changing its layout: the hit test accepts a band above and below the
/// child (the child gets the position clamped into itself).
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

/// Sets the size of every [AppChip] below it that doesn't pass its own [size]
/// (a list toolbar's chip row is [ChipSize.chip], one size down from the
/// search capsule it sits under).
class ChipSizeScope extends InheritedWidget {
  const ChipSizeScope({required this.size, required super.child, super.key});

  final ChipSize size;

  static ChipSize? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChipSizeScope>()?.size;

  @override
  bool updateShouldNotify(ChipSizeScope old) => size != old.size;
}
