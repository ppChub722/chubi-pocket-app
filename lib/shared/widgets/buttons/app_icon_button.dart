import 'package:flutter/material.dart';

/// Circular icon chip — the app's icon-button look (top bar actions, card
/// corners). Surface fill + hairline border + small shadow, optional badge.
///
/// - `onPressed: null` dims it (disabled).
/// - [destructive] tints the icon with the error colour (🗑).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount = 0,
    this.destructive = false,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int badgeCount;
  final bool destructive;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final iconColor = destructive ? scheme.error : scheme.onSurface;
    final iconWidget = Icon(icon, size: size * 0.55, color: iconColor);
    final visual = badgeCount > 0
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
            child: Center(child: visual),
          ),
        ),
      ),
    );
    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    return chip;
  }
}
