import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';
import 'module_colors.dart';

/// chubi-pocket's brand colours per kit theme: the module colours (and the
/// wallet colours) ride on each theme as a [ThemeExtension].
final _mintModules = (
  light: const ModuleColors(
    library: Color(0xFF10B981),
    people: Color(0xFF0EA5E9),
    planning: Color(0xFF6366F1),
    walletAsset: Color(0xFF0D9488),
    walletLiability: Color(0xFFEA580C),
  ),
  dark: const ModuleColors(
    library: Color(0xFF34D399),
    people: Color(0xFF38BDF8),
    planning: Color(0xFF818CF8),
    walletAsset: Color(0xFF2DD4BF),
    walletLiability: Color(0xFFFB923C),
  ),
);

final _sweetModules = (
  light: const ModuleColors(
    library: Color(0xFFEC4899),
    people: Color(0xFFF97316),
    planning: Color(0xFFA855F7),
    walletAsset: Color(0xFF0284C7),
    walletLiability: Color(0xFFEA580C),
  ),
  dark: const ModuleColors(
    library: Color(0xFFF472B6),
    people: Color(0xFFFB923C),
    planning: Color(0xFFC084FC),
    walletAsset: Color(0xFF38BDF8),
    walletLiability: Color(0xFFFB923C),
  ),
);

/// Registers the kit's built-in themes with chubi's [ModuleColors] attached.
/// Call once at start-up, before the first frame.
void configureChubiThemes() {
  ThemeRegistry.configure([
    mintTheme.withExtensions(
      light: [_mintModules.light],
      dark: [_mintModules.dark],
    ),
    sweetTheme.withExtensions(
      light: [_sweetModules.light],
      dark: [_sweetModules.dark],
    ),
  ], defaultThemeId: 'mint');
}

