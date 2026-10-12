import 'package:google_fonts/google_fonts.dart';

import 'font_registry.dart';

class FontPreloader {
  const FontPreloader._();

  /// Preloads every font declared in the registry.
  ///
  /// On Flutter web, `google_fonts` fetches font files asynchronously. If a
  /// text is painted before the font arrives, TextPainter can hit a layout
  /// assertion when font metrics update mid-frame. Calling this in `main()`
  /// before `runApp()` ensures the first paint already has font data.
  static Future<void> preloadAll() async {
    final families = FontRegistry.all.map((f) => f.family).toSet();
    await GoogleFonts.pendingFonts(
      families.map((name) => GoogleFonts.getFont(name)).toList(),
    );
  }
}
