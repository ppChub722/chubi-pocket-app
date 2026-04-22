import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fonts/app_font.dart';
import '../fonts/font_registry.dart';
import '../theme/app_theme.dart';
import '../theme/theme_builder.dart';
import '../theme/theme_registry.dart';
import 'font_id_provider.dart';
import 'theme_id_provider.dart';

final currentThemeProvider = Provider<AppTheme>((ref) {
  final id = ref.watch(themeIdProvider);
  return ThemeRegistry.byId(id);
});

final currentFontProvider = Provider<AppFont>((ref) {
  final id = ref.watch(fontIdProvider);
  return FontRegistry.byId(id);
});

final lightThemeDataProvider = Provider<ThemeData>((ref) {
  final theme = ref.watch(currentThemeProvider);
  final font = ref.watch(currentFontProvider);
  return ThemeBuilder.build(
    theme: theme,
    font: font,
    brightness: Brightness.light,
  );
});

final darkThemeDataProvider = Provider<ThemeData>((ref) {
  final theme = ref.watch(currentThemeProvider);
  final font = ref.watch(currentFontProvider);
  return ThemeBuilder.build(
    theme: theme,
    font: font,
    brightness: Brightness.dark,
  );
});
