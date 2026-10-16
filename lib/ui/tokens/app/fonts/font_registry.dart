import 'app_font.dart';

/// The fonts the app offers — ppForge's [builtIn] set unless the host app
/// [configure]s its own.
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
  /// The fonts ppForge ships. A host app offers its own set with [configure].
  static const List<PpForgeFont> builtIn = [
    inter,
    nunito,
    poppins,
    ibmPlexSansThai,
    mitr,
  ];

  static const Map<String, String> builtInDefaults = {
    'en': 'Inter',
    'th': 'IBM Plex Sans Thai',
  };

  static List<PpForgeFont> _all = builtIn;
  static Map<String, String> _defaults = builtInDefaults;

  static List<PpForgeFont> get all => _all;

  /// Per-language defaults — used when the app first launches and when the
  /// current font does not support a newly-selected locale.
  static Map<String, String> get defaultsByLanguage => _defaults;

  /// Replaces the offered fonts and the per-language defaults (ids from
  /// [fonts]) — once, before `runApp`.
  static void configure(
    List<PpForgeFont> fonts, {
    required Map<String, String> defaultsByLanguage,
  }) {
    assert(fonts.isNotEmpty, 'FontRegistry needs at least one font');
    assert(
      defaultsByLanguage.values.every((id) => fonts.any((f) => f.id == id)),
      'a default font is not in the list',
    );
    _all = List.unmodifiable(fonts);
    _defaults = Map.unmodifiable(defaultsByLanguage);
  }

  static String defaultIdFor(String languageCode) =>
      defaultsByLanguage[languageCode] ?? all.first.id;

  static PpForgeFont byId(String id) {
    return all.firstWhere((f) => f.id == id, orElse: () => all.first);
  }

  static List<PpForgeFont> availableFor(String languageCode) =>
      all.where((f) => f.supports(languageCode)).toList();
}
