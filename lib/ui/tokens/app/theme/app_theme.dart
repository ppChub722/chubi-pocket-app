import 'package:flutter/material.dart';

import '../../app_colors.dart';

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

  /// A host app's own [ThemeExtension]s (its brand colours, say), attached to
  /// the built [ThemeData] next to the kit's.
  final List<ThemeExtension<dynamic>> lightExtensions;
  final List<ThemeExtension<dynamic>> darkExtensions;

  List<ThemeExtension<dynamic>> extensionsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkExtensions : lightExtensions;

  /// This theme plus [light] / [dark] extensions of the host.
  PpForgeTheme withExtensions({
    List<ThemeExtension<dynamic>> light = const [],
    List<ThemeExtension<dynamic>> dark = const [],
  }) => PpForgeTheme(
    id: id,
    nameKey: nameKey,
    isPremium: isPremium,
    lightColors: lightColors,
    darkColors: darkColors,
    previewSwatch: previewSwatch,
    sku: sku,
    lightExtensions: [...lightExtensions, ...light],
    darkExtensions: [...darkExtensions, ...dark],
  );

  final String id;
  final String nameKey;
  final bool isPremium;
  final String? sku;
  final PpForgeColors lightColors;
  final PpForgeColors darkColors;
  final List<Color> previewSwatch;

  PpForgeColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkColors : lightColors;
}
