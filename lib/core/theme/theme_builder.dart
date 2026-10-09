import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_radius.dart';
import '../fonts/app_font.dart';
import 'app_theme.dart';

class ThemeBuilder {
  const ThemeBuilder._();

  static ThemeData build({
    required AppTheme theme,
    required AppFont font,
    required Brightness brightness,
  }) {
    final colors = theme.colorsFor(brightness);
    final colorScheme = colors.toColorScheme();
    final textTheme = _buildTextTheme(font: font, onSurface: colors.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: textTheme,
      extensions: [colors, ?theme.modulesFor(brightness)],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: systemBarsStyle(colors.background),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.outlineSoft),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  /// Status / nav bar icons contrast with the [background] that actually
  /// shows behind them — not the top bar's colour: [AppTopBar] is
  /// transparent, which Flutter reads as "dark" → white icons on our light
  /// background. Light background → dark icons, dark → light.
  static SystemUiOverlayStyle systemBarsStyle(Color background) {
    final bg = ThemeData.estimateBrightnessForColor(background);
    final icons = bg == Brightness.light ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      // iOS names the bar's background, not its icons.
      statusBarBrightness: bg,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
    );
  }

  static TextTheme _buildTextTheme({
    required AppFont font,
    required Color onSurface,
  }) {
    final base = ThemeData(
      brightness: Brightness.light,
    ).textTheme.apply(bodyColor: onSurface, displayColor: onSurface);
    return GoogleFonts.getTextTheme(font.family, base);
  }
}
