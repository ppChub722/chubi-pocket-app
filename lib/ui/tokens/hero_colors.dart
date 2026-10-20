import 'package:flutter/material.dart';

import 'app/app_colors.dart';
import 'color_contrast.dart';

/// The colors a hero card hands to the pieces inside it, all made from the
/// card's one color (the theme's primary when it has none). A piece reads
/// them with [HeroColors.maybeOf] instead of picking theme tokens itself.
@immutable
class HeroColors {
  const HeroColors({
    required this.accent,
    required this.soft,
    required this.line,
    required this.track,
    required this.text,
    required this.muted,
    required this.warning,
    required this.danger,
    required this.success,
  });

  factory HeroColors.from(ThemeData theme, Color? color) {
    final scheme = theme.colorScheme;
    final palette = theme.extension<AppColors>();
    final surface = scheme.surface;
    final accent = ensureContrast(color ?? scheme.primary, surface);
    Color wash(double alpha) =>
        Color.alphaBlend(accent.withValues(alpha: alpha), surface);
    return HeroColors(
      accent: accent,
      soft: wash(0.09),
      line: wash(0.26),
      track: wash(0.17),
      text: scheme.onSurface,
      muted: Color.lerp(scheme.onSurfaceVariant, accent, 0.18)!,
      warning: palette?.warning ?? scheme.tertiary,
      danger: palette?.error ?? scheme.error,
      success: palette?.success ?? scheme.primary,
    );
  }

  /// Big numbers, a bar's fill, the today line, icons.
  final Color accent;

  /// A quiet fill: a chip or a box inside the card.
  final Color soft;

  /// Borders inside the card.
  final Color line;

  /// The empty part of a bar.
  final Color track;

  final Color text;

  /// Labels, captions, the meta line.
  final Color muted;

  final Color warning;
  final Color danger;
  final Color success;

  /// The set of the hero around [context]; null outside one.
  static HeroColors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HeroColorScope>()?.colors;

  @override
  bool operator ==(Object other) =>
      other is HeroColors &&
      other.accent == accent &&
      other.soft == soft &&
      other.line == line &&
      other.track == track &&
      other.text == text &&
      other.muted == muted &&
      other.warning == warning &&
      other.danger == danger &&
      other.success == success;

  @override
  int get hashCode => Object.hash(
    accent,
    soft,
    line,
    track,
    text,
    muted,
    warning,
    danger,
    success,
  );
}

/// Puts a [HeroColors] in reach of everything below it; the hero surface
/// does this, so pages only ever set the card's color.
class HeroColorScope extends InheritedWidget {
  const HeroColorScope({required this.colors, required super.child, super.key});

  final HeroColors colors;

  @override
  bool updateShouldNotify(HeroColorScope old) => colors != old.colors;
}
