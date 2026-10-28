import '../../chip_size.dart';
import '../../hero_metrics.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_radius.dart';
import '../../app_spacing.dart';
import '../app_colors.dart';
import '../fonts/app_font.dart';
import 'app_page_transitions.dart';
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
    final menuStyle = _menuStyle(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: textTheme,
      extensions: [
        colors,
        const ControlSizes(),
        const HeroMetrics(),
        ?theme.modulesFor(brightness),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
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
      // Every dropdown / popover menu: one step above the cards
      // (surfaceVariant), a faint outline edge and a clear shadow, so an open
      // menu never blends into the card behind it (dark themes especially).
      menuTheme: MenuThemeData(style: menuStyle),
      dropdownMenuTheme: DropdownMenuThemeData(menuStyle: menuStyle),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceVariant,
        surfaceTintColor: Colors.transparent,
        shadowColor: _menuShadow(colors.brightness),
        elevation: _menuElevation,
        shape: _menuShape(colors),
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

  static const double _menuElevation = 8;

  static Color _menuShadow(Brightness brightness) =>
      brightness == Brightness.dark
      ? Colors.black
      : Colors.black.withValues(alpha: 0.35);

  static RoundedRectangleBorder _menuShape(AppColors colors) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.7)),
      );

  static MenuStyle _menuStyle(AppColors colors) => MenuStyle(
    backgroundColor: WidgetStatePropertyAll(colors.surfaceVariant),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(_menuShadow(colors.brightness)),
    elevation: const WidgetStatePropertyAll(_menuElevation),
    shape: WidgetStatePropertyAll(_menuShape(colors)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(vertical: AppSpacing.xs),
    ),
  );

  static SystemUiOverlayStyle systemBarsStyle(Color background) {
    final bg = ThemeData.estimateBrightnessForColor(background);
    final icons = bg == Brightness.light ? Brightness.dark : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
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
