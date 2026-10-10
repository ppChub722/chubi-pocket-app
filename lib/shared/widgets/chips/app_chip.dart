import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import 'pill.dart';

/// [AppChip]'s colour, by meaning. [color] on the chip overrides it with
/// any colour (a category's, a tag's, a wallet's accent).
enum AppChipTone {
  primary,

  /// Grey even when selected — a quiet label ("ผ่อน", "แบบเกิดซ้ำ").
  neutral,
  income,
  expense,

  /// Transfers have no colour of their own — the neutral grey.
  transfer,
  walletAsset,
  walletLiability,
  warning,
  success,
  danger,
  info;

  Color resolve(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      primary => scheme.primary,
      neutral || transfer => scheme.onSurfaceVariant,
      income => palette.income,
      expense => palette.expense,
      walletAsset => palette.walletAsset,
      walletLiability => palette.walletLiability,
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

/// The one chip (owner 2026-10-11, step 1 — for review; nothing uses it
/// yet). The filter sheet's look ([RowChip]): a stadium; unselected = a
/// grey outline with grey text (a custom [tone] / [color] still tints the
/// icon), selected = a border and a faint fill in its colour.
///
///   [● | icon | avatar]  label  [▾ | ✕ | 🔒 | n]
///
/// - **Interactive:** [onTap] + [selected]. A display chip (a status, a
///   type, a tag on a detail page) has no [onTap] and usually
///   `selected: true`, so it wears its colour.
/// - **Size:** two only (owner 2026-10-11) — [PillSize.normal] (32), the
///   default, for every chip; [PillSize.mini] (20) only for the tags on a
///   transaction list row. Same side padding and text for every normal
///   chip, so they differ only by their label. The height is the size's,
///   whatever the content.
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
    this.size = PillSize.normal,
    this.enabled = true,
    this.tooltip,
    super.key,
  }) : assert(
         trailing != AppChipTrailing.remove || onRemove != null,
         'AppChipTrailing.remove needs onRemove',
       );

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

  /// [PillSize.normal], or [PillSize.mini] on a transaction list row.
  final PillSize size;
  final bool enabled;

  /// A tap-to-read hint (why it's locked, what ✕ drops).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
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
              width: size.height - 10,
              height: size.height - 10,
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
      AppChipTrailing.count => _Count(
        count: count,
        color: fg,
        height: iconSize + 2,
      ),
    };

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: size
          .textStyle(context)
          ?.copyWith(color: fg, fontWeight: PillSize.chipWeight),
    );

    final sidePad = size.padding;
    final chip = Material(
      color: selected ? tint.withValues(alpha: 0.12) : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? tint : scheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Padding(
            padding: EdgeInsets.only(
              left: sidePad,
              // ▾ / ✕ carry their own air.
              right: tail == null ? sidePad : sidePad - AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lead != null) ...[lead, SizedBox(width: gap)],
                if (dotMark != null) ...[dotMark, SizedBox(width: gap)],
                Flexible(child: text),
                if (tail != null) ...[const SizedBox(width: 3), tail],
              ],
            ),
          ),
        ),
      ),
    );

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
    return out;
  }
}

/// [AppChipTrailing.count]: the number on a faint stadium of [color].
class _Count extends StatelessWidget {
  const _Count({
    required this.count,
    required this.color,
    required this.height,
  });
  final int count;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: height, minHeight: height),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
