import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import 'app_icon.dart';

/// What a long-running job tied to an [AppIconButton] is doing — shown
/// under the icon (e.g. the Pending chip while slips are being read).
enum IconChipActivity {
  /// Nothing — the plain chip.
  none,

  /// A thin progress bar under the icon; the badge is hidden meanwhile.
  progress,

  /// A small ✓ under the icon (until the user opens what it's about); the
  /// badge is back.
  done,
}

/// Circular icon chip — the app's icon-button look (top bar actions, card
/// corners). Surface fill + hairline border + small shadow, optional badge.
///
/// - `onPressed: null` dims it (disabled).
/// - [destructive] tints the icon with the error colour (🗑).
/// - [activity] shows a job's progress / completion under the icon;
///   [progress] 0–1 (null = indeterminate).
///
/// Variants (owner 2026-10-12 — every recurring icon button is one of these):
/// - `AppIconButton(...)` — the chip itself (top-bar actions, hero corners);
/// - `AppIconButton.edit(...)` — the round ✏️ ("edit" in a hero's top row,
///   "enter edit / reorder mode" in a list header): [sizeHero] 32 or
///   [sizeList] 36;
/// - the FLAT ones, no chip — `.flat` (any icon), `.close` ✕, `.clear` ✕ (a
///   field or row's remove), `.more` ⋯, `.back` ←: a plain 48-dp tap target
///   with the icon at [iconSize] and [color]; [dense] shrinks the target.
class AppIconButton extends StatelessWidget {
  /// A hero's ✏️ (the same height as the chips beside it).
  static const double sizeHero = 32;

  /// A list header's ✏️ ("enter edit / reorder mode").
  static const double sizeList = 36;

  /// The top bar's chips.
  static const double sizeBar = 40;

  const AppIconButton({
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
  const AppIconButton.edit({
    required this.onPressed,
    this.tooltip,
    this.size = sizeList,
    super.key,
  }) : icon = AppIcons.edit,
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
  const AppIconButton.flat({
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
  const AppIconButton.close({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.close,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ✕ — clear / remove a field's value or a row.
  const AppIconButton.clear({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.clear,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ⋯ — a row's menu.
  const AppIconButton.more({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.more,
       size = 40,
       badgeCount = 0,
       destructive = false,
       selected = false,
       activity = IconChipActivity.none,
       progress = null,
       _flat = true;

  /// ← — back.
  const AppIconButton.back({
    required this.onPressed,
    this.tooltip,
    this.iconSize,
    this.color,
    this.dense = false,
    super.key,
  }) : icon = AppIcons.back,
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
        icon: AppIcon(icon, size: iconSize),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final iconColor = destructive
        ? scheme.error
        : selected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final iconWidget = Icon(icon, size: size * 0.55, color: iconColor);
    final working = activity == IconChipActivity.progress;
    final visual = badgeCount > 0 && !working
        ? Badge(
            label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
            child: iconWidget,
          )
        : iconWidget;

    Widget chip = Opacity(
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
            child: activity == IconChipActivity.none
                ? Center(child: visual)
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: size * 0.16),
                        child: visual,
                      ),
                      Positioned(
                        bottom: size * 0.17,
                        child: working
                            ? SizedBox(
                                width: size * 0.42,
                                height: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    color: scheme.primary,
                                    backgroundColor:
                                        scheme.surfaceContainerHighest,
                                  ),
                                ),
                              )
                            : Icon(
                                AppIcons.check,
                                size: size * 0.26,
                                color: scheme.primary,
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    return chip;
  }
}
