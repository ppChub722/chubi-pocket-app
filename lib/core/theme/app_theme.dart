import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'module_colors.dart';

@immutable
class AppTheme {
  const AppTheme({
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
  final AppColors lightColors;
  final AppColors darkColors;
  final List<Color> previewSwatch;

  AppColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkColors : lightColors;
}
