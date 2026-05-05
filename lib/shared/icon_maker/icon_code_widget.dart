import 'package:flutter/material.dart';

import 'icon_code.dart';
import 'icon_registry.dart';

/// How the icon should be rendered visually.
enum IconDisplayStyle {
  /// Solid circle background with a white icon. Used by accounts, categories,
  /// projects, and contacts.
  background,

  /// No background — icon rendered in its accent colour. Used by tags.
  iconColor,
}

/// Renders an [IconCode] as a fixed-diameter circle.
///
/// Handles null gracefully — shows a fallback icon in the fallback colour.
/// Pass an [EditableCircle] wrapper above this widget when the icon should
/// also be tappable with a pencil badge.
class IconCodeWidget extends StatelessWidget {
  const IconCodeWidget({
    required this.iconCode,
    required this.size,
    this.style = IconDisplayStyle.background,
    this.fallbackIcon = Icons.category_outlined,
    this.fallbackColor = const Color(0xFF64B5F6),
    super.key,
  });

  final IconCode? iconCode;
  final double size;
  final IconDisplayStyle style;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final ic = iconCode;
    final iconData = IconRegistry.get(ic?.icon, fallback: fallbackIcon);

    if (style == IconDisplayStyle.iconColor) {
      final color = ic?.resolvedIconColor ?? fallbackColor;
      return SizedBox(
        width: size,
        height: size,
        child: Icon(iconData, size: size * 0.7, color: color),
      );
    }

    final bgColor = ic?.resolvedBgColor ?? fallbackColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, size: size * 0.55, color: Colors.white),
    );
  }
}
