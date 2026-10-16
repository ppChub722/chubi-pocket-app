import 'package:flutter/material.dart';

import '../app_colors.dart';

@immutable
class PpForgeTheme {
  const PpForgeTheme({
    required this.id,
    required this.nameKey,
    required this.isPremium,
    required this.lightColors,
    required this.darkColors,
    required this.previewSwatch,
    this.sku,
    this.lightExtensions = const [],
    this.darkExtensions = const [],
  });

  /// The host app's own [ThemeExtension]s (e.g. its feature-group colours),
  /// installed next to [PpForgeColors] by `ThemeBuilder`. Add them to a
  /// ready-made theme with [withExtensions].
  final List<ThemeExtension<dynamic>> lightExtensions;
  final List<ThemeExtension<dynamic>> darkExtensions;

  List<ThemeExtension<dynamic>> extensionsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkExtensions : lightExtensions;

  final String id;
  final String nameKey;
  final bool isPremium;
  final String? sku;
  final PpForgeColors lightColors;
  final PpForgeColors darkColors;
  final List<Color> previewSwatch;

  PpForgeColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkColors : lightColors;

  /// This theme with the host app's [light] / [dark] extensions.
  PpForgeTheme withExtensions({
    List<ThemeExtension<dynamic>> light = const [],
    List<ThemeExtension<dynamic>> dark = const [],
  }) => PpForgeTheme(
    id: id,
    nameKey: nameKey,
    isPremium: isPremium,
    sku: sku,
    lightColors: lightColors,
    darkColors: darkColors,
    previewSwatch: previewSwatch,
    lightExtensions: light,
    darkExtensions: dark,
  );
}
