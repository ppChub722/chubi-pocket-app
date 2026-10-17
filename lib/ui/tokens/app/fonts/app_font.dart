import 'package:flutter/foundation.dart';

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

  final String id;

  final String family;

  final Set<String> supportedLanguages;

  final bool isPremium;
  final String? sku;

  final String previewSample;

  bool supports(String languageCode) =>
      supportedLanguages.contains(languageCode);

  String get displayName => family;
}
