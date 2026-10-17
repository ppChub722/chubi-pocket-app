import 'dart:math' as math;

class AvatarMetrics {
  const AvatarMetrics._();

  /// The named avatar sizes (a list row 32, a card 40, a hero chip 44) — never
  /// a literal in a feature.
  static const double sizeSmall = 32;
  static const double sizeMedium = 40;
  static const double sizeLarge = 44;

  static const double _min = 20;
  static const double _max = 64;

  static double _t(double size) =>
      ((size - _min) / (_max - _min)).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double size) =>
      a + (b - a) * _t(size);

  static double glyphFraction(double size) => _lerp(0.72, 0.50, size);

  static double glyph(double size) => size * glyphFraction(size);

  static double initials(double size) => size * _lerp(0.52, 0.42, size);

  static double frame(double size, {bool thick = false}) {
    final w = _lerp(1.0, 2.5, size);
    return math.min(thick ? w * 2 : w, size / 4);
  }

  static double badgeGlyph(double size) => glyph(size);

  static const double minCornerBadgeAvatar = 40;

  static const double minEditableAvatar = 40;

  static bool showsCornerBadge(double size) => size >= minCornerBadgeAvatar;

  static double cornerBadge(double size) => (size * 0.34).clamp(16.0, 28.0);

  static double cornerBadgeGlyph(double badge) => badge * 0.62;
}
