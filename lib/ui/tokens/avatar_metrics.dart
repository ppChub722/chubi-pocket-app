import 'dart:math' as math;

/// How a framed avatar / icon circle scales with its size (owner 2026-10-12):
/// the frame thickness and the frame-to-glyph padding follow the size, and the
/// smaller the avatar the LARGER the glyph is relative to it (less padding), so
/// a 20 px avatar is not a tiny icon in an empty ring.
///
/// Every framed avatar (PpForgeAvatar, the icon maker's IconCodeWidget, IconTile,
/// the corner badges, the pencil badge of EditableCircle) takes its numbers from
/// here — never a literal fraction. The ladder (the hub page atoms/badge-avatar
/// shows it):
///
/// | size | glyph | initials | frame |
/// |---|---|---|---|
/// | 20 | 0.72 | 0.52 | 1.0 |
/// | 24 | 0.70 | 0.51 | 1.1 |
/// | 32 | 0.66 | 0.49 | 1.4 |
/// | 40 | 0.62 | 0.47 | 1.7 |
/// | 48 | 0.58 | 0.45 | 2.0 |
/// | 64 | 0.50 | 0.42 | 2.5 |
class AvatarMetrics {
  const AvatarMetrics._();

  /// The named avatar sizes (a list row 32, a card 40, a hero chip 44) — never
  /// a literal in a feature.
  static const double sizeSmall = 32;
  static const double sizeMedium = 40;
  static const double sizeLarge = 44;

  static const double _min = 20;
  static const double _max = 64;

  /// 0 at 20 px (and below) … 1 at 64 px (and above).
  static double _t(double size) =>
      ((size - _min) / (_max - _min)).clamp(0.0, 1.0);

  static double _lerp(double a, double b, double size) =>
      a + (b - a) * _t(size);

  /// The glyph's edge as a fraction of the avatar: 0.72 at 20 → 0.50 at 64.
  static double glyphFraction(double size) => _lerp(0.72, 0.50, size);

  /// The glyph's size inside a [size] frame.
  static double glyph(double size) => size * glyphFraction(size);

  /// The initials' font size inside a [size] avatar: 0.52 → 0.42 of it.
  static double initials(double size) => size * _lerp(0.52, 0.42, size);

  /// The frame (border) width of a [size] avatar: 1 → 2.5 (a "thick" frame
  /// doubles it).
  static double frame(double size, {bool thick = false}) {
    final w = _lerp(1.0, 2.5, size);
    return math.min(thick ? w * 2 : w, size / 4);
  }

  /// A badge's glyph inside a [size] badge (the same ladder).
  static double badgeGlyph(double size) => glyph(size);

  /// The smallest avatar that carries a corner badge (edit pencil, 🔗 link,
  /// type glyph) — owner 2026-10-12. Below it the badge would cover a third of
  /// the avatar, so it is left out (an editable avatar is never smaller).
  static const double minCornerBadgeAvatar = 40;

  /// The same floor for an editable circle (its pencil is its whole point).
  static const double minEditableAvatar = 40;

  /// Whether an avatar of [size] shows a corner badge.
  static bool showsCornerBadge(double size) => size >= minCornerBadgeAvatar;

  /// A corner badge's diameter on an avatar of [size]: a third of it, between
  /// 16 and 28 — so at the 40 minimum it is 16 (40 %), at 64 it is 22.
  static double cornerBadge(double size) => (size * 0.34).clamp(16.0, 28.0);

  /// The glyph inside a corner badge of diameter [badge].
  static double cornerBadgeGlyph(double badge) => badge * 0.62;
}
