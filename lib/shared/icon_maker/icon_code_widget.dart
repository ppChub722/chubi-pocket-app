import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'color_token.dart';
import 'icon_code.dart';
import 'icon_registry.dart';

/// Controls which visual layers [IconCodeWidget] renders.
///
/// Use [full] in detail views, forms, and profile headers where every
/// layer should appear at full fidelity.
/// Use [compact] in list rows and small avatars — border is suppressed
/// even when the [IconCode] has one set, keeping dense UIs uncluttered.
enum IconDisplayMode {
  full,
  compact,
}

/// Renders an [IconCode] as a fixed-diameter widget.
///
/// Type-unaware — resolves colour specs (hex literals or `@presetTheme*`
/// tokens) through the active [AppColors] palette so theme tokens follow
/// the active theme.
///
/// | IconCode state              | Renders                                   |
/// |-----------------------------|-------------------------------------------|
/// | `iconCode == null`          | fallback circle + fallback icon           |
/// | `background != null`        | named background circle + icon glyph      |
/// | `background == null`        | icon glyph only (no circle)               |
/// | `borderColors` non-empty    | solid border ring (dashed = approximated) |
/// | `superGradientA` / `radialGlow` / `stripedPatternDi` | gradient fill |
/// | `rainbow`                   | ROYGBIV sweep                             |
class IconCodeWidget extends StatelessWidget {
  const IconCodeWidget({
    required this.iconCode,
    required this.size,
    this.displayMode = IconDisplayMode.full,
    this.fallbackIcon = Icons.category_outlined,
    this.fallbackColor = const Color(0xFF64B5F6),
    super.key,
  });

  final IconCode? iconCode;
  final double size;
  final IconDisplayMode displayMode;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final ic = iconCode;
    final iconData = IconRegistry.get(ic?.icon, fallback: fallbackIcon);

    // null iconCode → fallback circle
    if (ic == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fallbackColor),
        child: Icon(iconData, size: size * 0.55, color: Colors.white),
      );
    }

    final hasBg = ic.background != null;
    final iconColor = ic.iconColors.isNotEmpty
        ? resolveColor(ic.iconColors.first, palette)
        : (hasBg ? palette.onPrimary : fallbackColor);

    // null background → icon glyph only, no circle
    if (!hasBg) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(iconData, size: size * 0.7, color: iconColor),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: _buildDecoration(ic, palette),
      child: Icon(iconData, size: size * 0.55, color: iconColor),
    );
  }

  BoxDecoration _buildDecoration(IconCode ic, AppColors palette) {
    final border = _buildBorder(ic, palette);
    final colors = ic.bgColors;
    Color c(int i) => resolveColor(colors[i], palette);

    return switch (ic.background) {
      'superGradientA' when colors.length >= 2 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c(0), c(1)],
          ),
          border: border,
        ),
      'radialGlow' when colors.length >= 2 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [c(0), c(1)],
          ),
          border: border,
        ),
      'stripedPatternDi' when colors.length >= 3 => BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c(0), c(0), c(1), c(1), c(2), c(2)],
            stops: const [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
          ),
          border: border,
        ),
      'rainbow' => BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFFEF4444),
              Color(0xFFF59E0B),
              Color(0xFFFCD34D),
              Color(0xFF22C55E),
              Color(0xFF3B82F6),
              Color(0xFF6366F1),
              Color(0xFFA855F7),
              Color(0xFFEF4444),
            ],
          ),
          border: border,
        ),
      // Preset backgrounds — no user-controlled colors.
      // True textures (patterns, illustrations) are deferred; placeholder color used for now.
      'snowflake' => BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFDBEAFE),
          border: border,
        ),
      'wreath' => BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF15803D),
          border: border,
        ),
      'starburst' => BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF15803D),
          border: border,
        ),
      // 'solid' or any unrecognised id → use bgColors[0]
      _ => BoxDecoration(
          shape: BoxShape.circle,
          color: colors.isNotEmpty ? c(0) : fallbackColor,
          border: border,
        ),
    };
  }

  Border? _buildBorder(IconCode ic, AppColors palette) {
    if (displayMode == IconDisplayMode.compact) return null;
    if (ic.border == null || ic.borderColors.isEmpty) return null;
    final color = resolveColor(ic.borderColors.first, palette);
    return switch (ic.border) {
      'thick' => Border.all(color: color, width: 4),
      _ => Border.all(color: color, width: 2),
    };
  }
}
