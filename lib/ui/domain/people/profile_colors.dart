import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';
import '../../tokens/color_contrast.dart';
import '../icons/color_token.dart';
import 'avatar_data.dart';

/// Picks a person's colours from their profile colours (`avatar.colors`,
/// colour 1 = the main one) for a page: hero tints, the settings card, split
/// pills. Every colour it returns has passed [ensureContrast] against the
/// surface it sits on.
abstract final class ProfileColors {
  /// Slot [n] (0 = colour 1). An unset slot (past the end, or empty) takes
  /// the nearest set slot below it; none set → [fallback] (else the theme
  /// primary).
  static Color slot(
    List<String> colors,
    int n, {
    required AppColors palette,
    required Color surface,
    Color? fallback,
  }) {
    final spec = _slotSpec(colors, n);
    final color = spec == null
        ? (fallback ?? palette.primary)
        : resolveColor(spec, palette);
    return ensureContrast(color, surface);
  }

  /// Colour 1 of [avatar] (its main colour).
  static Color main(
    AvatarData avatar, {
    required AppColors palette,
    required Color surface,
  }) => slot(avatar.colors, 0, palette: palette, surface: surface);

  /// Slot [n] of [avatar] in the theme of [context], against its surface.
  static Color of(BuildContext context, AvatarData avatar, {int n = 0}) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppColors>();
    final surface = theme.colorScheme.surface;
    if (palette == null) {
      return ensureContrast(theme.colorScheme.primary, surface);
    }
    return slot(avatar.colors, n, palette: palette, surface: surface);
  }

  /// [k] colours that differ: the set ones in order (repeats dropped), then
  /// lighter / darker shades of them when fewer than [k] are set.
  static List<Color> distinct(
    List<String> colors,
    int k, {
    required AppColors palette,
    required Color surface,
    Color? fallback,
  }) {
    if (k <= 0) return const [];
    final base = <Color>[];
    for (final spec in colors) {
      if (spec.isEmpty) continue;
      final c = resolveColor(spec, palette);
      if (!base.any((b) => b.toARGB32() == c.toARGB32())) base.add(c);
    }
    if (base.isEmpty) base.add(fallback ?? palette.primary);
    final out = base.take(k).toList();
    // Shades: every base colour lighter, then darker, in rounds that step
    // further each time.
    for (var round = 1; out.length < k; round++) {
      final t = (0.22 * round).clamp(0.0, 0.9);
      for (final b in base) {
        if (out.length >= k) break;
        out.add(Color.lerp(b, const Color(0xFFFFFFFF), t)!);
        if (out.length >= k) break;
        out.add(Color.lerp(b, const Color(0xFF000000), t)!);
      }
    }
    return [for (final c in out) ensureContrast(c, surface)];
  }

  static String? _slotSpec(List<String> colors, int n) {
    if (colors.isEmpty) return null;
    for (var i = n.clamp(0, colors.length - 1); i >= 0; i--) {
      if (colors[i].isNotEmpty) return colors[i];
    }
    return null;
  }
}
