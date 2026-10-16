import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_icon.dart';
import 'count_badge.dart';

/// What a long-running job tied to an [PpForgeIconButton] is doing — shown
/// under the icon (e.g. the Pending chip while slips are being read).
enum IconChipActivity {
  /// Nothing — the plain chip.
  none,

  /// A thin progress bar overlaid under the icon (the icon stays put); the
  /// badge is hidden meanwhile.
  progress,

  /// The icon kept in place at ~0.3 opacity with a ✓ drawn ON TOP of it
  /// (until the user opens what it's about); the badge is back.
  done,
}

/// Circular icon chip — the app's icon-button look (top bar actions, card
/// corners). Surface fill + hairline border + small shadow, optional badge.
///
/// - `onPressed: null` dims it (disabled).
/// - [destructive] tints the icon with the error colour (🗑).
/// - [activity] shows a job's progress / completion WITHOUT moving the icon:
///   progress = a thin bar overlaid under it, done = the icon kept at ~0.3
///   opacity with a ✓ drawn on top of it; [progress] 0–1 (null = indeterminate). The size never changes.
/// - [badgeCount] floats outside the circle, top-right, half past its edge,
///   in a page-colour ring (hidden while a job runs).
///
/// Variants (owner 2026-10-12 — every recurring icon button is one of these):
/// - `PpForgeIconButton(...)` — the chip itself (top-bar actions, hero corners);
/// - `PpForgeIconButton.edit(...)` — the round ✏️ ("edit" in a hero's top row,
///   "enter edit / reorder mode" in a list header): [sizeHero] / [sizeList], both the one control height 40;
/// - the FLAT ones, no chip — `.flat` (any icon), `.close` ✕, `.clear` ✕ (a
///   field or row's remove), `.more` ⋯, `.back` ←: a plain 48-dp tap target
///   with the icon at [iconSize] and [color]; [dense] shrinks the target.
class PpForgeIconButton extends StatelessWidget {
  /// A hero's ✏️ (the same height as the chips beside it).
  static const double sizeHero = 40;

  /// A list header's ✏️ ("enter edit / reorder mode").
  static const double sizeList = 40;

  /// The top bar's chips.
  static const double sizeBar = 40;

  const PpForgeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
    this.destructive = false,
    this.selected = false,
    this.size = 40,
    this.activity = IconChipActivity.none,
    this.progress,
    super.key,
  }) : _flat = false,
       iconSize = null,
       color = null,
       dense = false;

  /// The round ✏️ chip.
  const PpForgeIconButton.edit({
    required this.onPressed,
    this.tooltip,
    this.size = sizeList,
    super.key,
  }) : icon = PpForgeIcons.edit,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = false,
       iconSize = null,
       color = null,
       dense = false;

  /// A plain icon button, any icon (a trash in a bar, an eye toggle).
  const PpForgeIconButton.flat({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ✕ — close a sheet / banner / dialog.
  const PpForgeIconButton.close({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = PpForgeIcons.close,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ✕ — clear / remove a field's value or a row.
  const PpForgeIconButton.clear({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = PpForgeIcons.clear,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ⋯ — a row's menu.
  const PpForgeIconButton.more({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = PpForgeIcons.more,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ← — back.
  const PpForgeIconButton.back({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = PpForgeIcons.back,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  final bool _flat;

  /// Flat variants: the icon's size (null = 24) and colour (null = inherit),
  /// and a smaller tap target.
  final double? iconSize;
  final Color? color;
  final bool dense;

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int badgeCount;
  final bool destructive;

  /// The page this chip stands for is on screen: the bottom nav's active
  /// look (primary-container fill, on-primary-container icon).
  final bool selected;
  final double size;
  final IconChipActivity activity;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (_flat) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: dense ? VisualDensity.compact : null,
        color: color,
        icon: PpForgeIcon(icon, size: iconSize),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final iconColor = destructive
        ? scheme.error
        : selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final working = activity == IconChipActivity.progress;
    final done = activity == IconChipActivity.done;
    final glyphSize = size * 0.55;
    // The icon never moves: in "done" it stays in place at ~0.3 opacity and a
    // ✓ is drawn ON TOP of it, centred in the same slot (a quick fade); in
    // "progress" the indicator is overlaid under it. The button's size is the
    // same in every state.
    const fade = Duration(milliseconds: 160);
    final glyph = Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: fade,
          opacity: done ? 0.3 : 1,
          child: Icon(icon, size: glyphSize, color: iconColor),
        ),
        AnimatedOpacity(
          duration: fade,
          opacity: done ? 1 : 0,
          child: Icon(
            PpForgeIcons.check,
            size: glyphSize,
            color: scheme.primary,
          ),
        ),
      ],
    );

    final circle = Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        elevation: enabled ? 1.5 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                glyph,
                if (working)
                  Positioned(
                    bottom: size * 0.1,
                    child: SizedBox(
                      width: size * 0.42,
                      height: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // The count floats OUTSIDE the circle: anchored top-right, about half of
    // it past the edge, ringed in the page colour (CornerBadge's idea, at the
    // other corner). Hidden while a job runs.
    // The shared count badge, floating off the circle's top-right corner
    // (hidden while a job runs).
    Widget chip = working
        ? circle
        : CountBadge.floating(child: circle, count: badgeCount);
    // Anchored to the button's OWN bounds, whatever the parent's width: under
    // a tight width (a stretched Column) the Stack would otherwise fill it and
    // the badge would land on the parent's far edge. The button keeps its own
    // size, at the start; the badge hangs off its top-right corner.
    chip = UnconstrainedBox(
      alignment: AlignmentDirectional.topStart,
      child: chip,
    );
    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    return chip;
  }
}
