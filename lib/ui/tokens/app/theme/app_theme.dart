import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../module_colors.dart';

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
    this.lightModules,
    this.darkModules,
  });

  /// Feature-group colours (the เพิ่มเติม hub's sections). Null → the
  /// theme's primary for every group (see [ModuleColors.of]).
  final ModuleColors? lightModules;
  final ModuleColors? darkModules;

  ModuleColors? modulesFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkModules : lightModules;

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
