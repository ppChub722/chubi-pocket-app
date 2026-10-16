import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';
import 'module_colors.dart';

/// chubiPocket's themes: ppForge's Mint and Sweet, each with the app's
/// feature-group colours ([ModuleColors]) in its own family.
final chubiThemes = [
  // Cool family: emerald · sky · indigo.
  mintTheme.withExtensions(
    light: const [
      ModuleColors(
        library: Color(0xFF10B981),
        people: Color(0xFF0EA5E9),
        planning: Color(0xFF6366F1),
      ),
    ],
    dark: const [
      ModuleColors(
        library: Color(0xFF34D399),
        people: Color(0xFF38BDF8),
        planning: Color(0xFF818CF8),
      ),
    ],
  ),
  // Warm pink family: pink · peach · purple.
  sweetTheme.withExtensions(
    light: const [
      ModuleColors(
        library: Color(0xFFEC4899),
        people: Color(0xFFF97316),
        planning: Color(0xFFA855F7),
      ),
    ],
    dark: const [
      ModuleColors(
        library: Color(0xFFF472B6),
        people: Color(0xFFFB923C),
        planning: Color(0xFFC084FC),
      ),
    ],
  ),
];

/// Installs [chubiThemes] in ppForge's [ThemeRegistry]. Call once before
/// `runApp` (tests that need the module colours call it too).
void configureChubiThemes() =>
    ThemeRegistry.configure(chubiThemes, defaultThemeId: 'mint');
