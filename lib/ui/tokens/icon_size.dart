/// The icon sizes — one scale for every icon in the app (owner 2026-10-12).
/// Features never write a number: `PpForgeIcon(icon, size: PpForgeIconSize.md)`.
///
/// | token | px | for |
/// |---|---|---|
/// | [xs] | 12 | inside a mini chip / badge, a trailing hint |
/// | [sm] | 16 | inside a chip, a caption line |
/// | [md] | 20 | a row's secondary icon, a button icon |
/// | [lg] | 24 | the standard icon (Material default), list-row leading |
/// | [xl] | 32 | a feature icon, an empty-state glyph beside text |
/// | [hero] | 56 | an empty / error screen's big glyph |
class PpForgeIconSize {
  const PpForgeIconSize._();

  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double hero = 56;
}
