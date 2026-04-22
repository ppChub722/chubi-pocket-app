import 'package:flutter/foundation.dart';

/// A single font. Each font declares which languages it supports — the picker
/// uses this to show only fonts compatible with the current locale.
///
/// When adding a new font, you **must** set `supportedLanguages` so the app
/// can filter and auto-fallback correctly.
@immutable
class AppFont {
  const AppFont({
    required this.id,
    required this.family,
    required this.supportedLanguages,
    required this.previewSample,
    this.isPremium = false,
    this.sku,
  });

  /// Stable identifier used for persistence. Usually equals [family].
  final String id;

  /// Exact Google Fonts family name (e.g. `Inter`, `IBM Plex Sans Thai`).
  final String family;

  /// Language codes this font supports (e.g. `{'en'}` or `{'th'}`).
  final Set<String> supportedLanguages;

  final bool isPremium;
  final String? sku;

  /// Short sample shown in the font picker.
  final String previewSample;

  bool supports(String languageCode) =>
      supportedLanguages.contains(languageCode);

  /// Display name shown in UI — the font family itself.
  String get displayName => family;
}
