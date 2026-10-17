import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/avatar_metrics.dart';
import 'color_token.dart';
import 'icon_code.dart';
import 'icon_registry.dart';
import 'icon_shape.dart';

enum IconDisplayMode { full, compact }

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

    if (ic == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: fallbackColor),
        child: Icon(
          IconRegistry.get(null, fallback: fallbackIcon),
          size: AvatarMetrics.glyph(size),
          color: Colors.white,
        ),
      );
    }

    final radius = IconShape.fromId(ic.shape).radius(size);

    final hasIcon = ic.icon != null;
    final hasBg = ic.background != null;
    final iconColor = ic.iconColors.isNotEmpty
        ? resolveColor(ic.iconColors.first, palette)
        : (hasBg ? palette.onPrimary : fallbackColor);

    Widget glyph(double s) => hasIcon
        ? Icon(
            IconRegistry.get(ic.icon, fallback: fallbackIcon),
            size: s,
            color: iconColor,
          )
        : const SizedBox.shrink();

    // A frame eats into the room the glyph has: size it for the inside of the
    // frame (a thick frame on a 20 px avatar must not clip the glyph).
    final frame = _buildBorder(ic, palette)?.top.width ?? 0;
    final fitted = math.min(
      AvatarMetrics.glyph(size),
      (size - 2 * frame) * 0.86,
    );

    if (!hasBg) {
      final border = _buildBorder(ic, palette);
      if (border == null) {
        return SizedBox(
          width: size,
          height: size,
          child: Center(child: glyph(AvatarMetrics.glyph(size) * 1.12)),
        );
      }
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: radius, border: border),
        child: glyph(fitted),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: _buildDecoration(ic, palette, radius),
      child: glyph(fitted),
    );
  }

  BoxDecoration _buildDecoration(
    IconCode ic,
    AppColors palette,
    BorderRadius radius,
  ) {
    final border = _buildBorder(ic, palette);
    final colors = ic.bgColors;
    Color c(int i) => resolveColor(colors[i], palette);

    return switch (ic.background) {
      'superGradientA' when colors.length >= 2 => BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c(0), c(1)],
        ),
        border: border,
      ),
      'radialGlow' when colors.length >= 2 => BoxDecoration(
        borderRadius: radius,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 1.2,
          colors: [c(0), c(1)],
        ),
        border: border,
      ),
      'stripedPatternDi' when colors.length >= 3 => BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c(0), c(0), c(1), c(1), c(2), c(2)],
          stops: const [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
        ),
        border: border,
      ),
      'rainbow' => BoxDecoration(
        borderRadius: radius,
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
      'snowflake' => BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFFDBEAFE),
        border: border,
      ),
      'wreath' => BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFF15803D),
        border: border,
      ),
      'starburst' => BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFF15803D),
        border: border,
      ),
      _ => BoxDecoration(
        borderRadius: radius,
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
      'thick' => Border.all(
        color: color,
        width: AvatarMetrics.frame(size, thick: true),
      ),
      _ => Border.all(color: color, width: AvatarMetrics.frame(size)),
    };
  }
}
