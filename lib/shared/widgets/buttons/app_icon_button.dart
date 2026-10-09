import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';

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
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
    this.destructive = false,
    this.size = 40,
    this.activity = IconChipActivity.none,
    this.progress,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int badgeCount;
  final bool destructive;
  final double size;
  final IconChipActivity activity;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final iconColor = destructive ? scheme.error : scheme.onSurface;
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
        color: scheme.surfaceContainerHigh,
        elevation: enabled ? 1.5 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
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
