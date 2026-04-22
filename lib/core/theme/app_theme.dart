import 'package:flutter/material.dart';

import 'app_colors.dart';

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
  });

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
