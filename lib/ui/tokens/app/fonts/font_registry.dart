import 'app_font.dart';

/// Central registry of all fonts available in the app.
///
/// Adding a new font:
///   1. Append an [PpForgeFont] entry here.
///   2. Set `supportedLanguages` — this is mandatory.
///   3. The picker, preloader and fallback logic pick it up automatically.
class FontRegistry {
  const FontRegistry._();

  // ── English fonts (3) ────────────────────────────────────────────────────
  static const PpForgeFont inter = PpForgeFont(
    id: 'Inter',
    family: 'Inter',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  static const PpForgeFont nunito = PpForgeFont(
    id: 'Nunito',
    family: 'Nunito',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  static const PpForgeFont poppins = PpForgeFont(
    id: 'Poppins',
    family: 'Poppins',
    supportedLanguages: {'en'},
    previewSample: 'The quick brown fox 1,234',
  );

  // ── Thai fonts (2) ───────────────────────────────────────────────────────
  static const PpForgeFont ibmPlexSansThai = PpForgeFont(
    id: 'IBM Plex Sans Thai',
    family: 'IBM Plex Sans Thai',
    supportedLanguages: {'th'},
    previewSample: 'สวัสดี นักกีฬา ชมพู่ ๑,๒๓๔',
  );

  static const PpForgeFont mitr = PpForgeFont(
    id: 'Mitr',
    family: 'Mitr',
    supportedLanguages: {'th'},
    previewSample: 'สวัสดี นักกีฬา ชมพู่ ๑,๒๓๔',
  );

  // ── Aggregate ────────────────────────────────────────────────────────────
  static const List<PpForgeFont> all = [
    inter,
    nunito,
    poppins,
    ibmPlexSansThai,
    mitr,
  ];

  /// Per-language defaults — used when the app first launches and when the
  /// current font does not support a newly-selected locale.
  static const Map<String, String> defaultsByLanguage = {
    'en': 'Inter',
    'th': 'IBM Plex Sans Thai',
  };

  static String defaultIdFor(String languageCode) =>
      defaultsByLanguage[languageCode] ?? all.first.id;

  static PpForgeFont byId(String id) {
    return all.firstWhere((f) => f.id == id, orElse: () => all.first);
  }

  static List<PpForgeFont> availableFor(String languageCode) =>
      all.where((f) => f.supports(languageCode)).toList();
}
