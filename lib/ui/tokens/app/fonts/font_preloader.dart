import 'package:google_fonts/google_fonts.dart';

import 'font_registry.dart';

class FontPreloader {
  const FontPreloader._();

  static Future<void> preloadAll() async {
    final families = FontRegistry.all.map((f) => f.family).toSet();
    await GoogleFonts.pendingFonts(
      families.map((name) => GoogleFonts.getFont(name)).toList(),
    );
  }
}
