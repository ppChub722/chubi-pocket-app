import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Resolves a colour spec against the active [AppColors] palette.
///
/// A spec is one of:
/// - **Hex literal** — `#FF0000`, `#00A389` → returned as-is.
/// - **Theme token** — `@presetThemeColor1`, `@presetThemeColor2`,
///   `@presetThemeColor3`, `@presetThemeColorContainer`,
///   `@presetThemeColorOnIcon`, `@presetThemeColorBorder`.
///   Tokens accept optional shade modifiers: `Darker` / `Lighter` and an
///   optional amount in percent (default 20). Examples:
///     `@presetThemeColor1Darker`     → primary mixed with black 20%
///     `@presetThemeColor1Lighter40`  → primary mixed with white 40%
///
/// Token names are flat and visual (not Material role names) so the picker
/// UI can show them as `1`, `2`, `3` to the user. Internally each maps to
/// a slot on [AppColors].
///
/// User-saved [IconCode]s may contain either form. Tokens make a saved
/// code "follow the active theme"; hex pins it.
Color resolveColor(String spec, AppColors palette) {
  if (spec.isEmpty) return palette.primary;
  if (spec.startsWith('#')) return _parseHex(spec) ?? palette.primary;
  if (spec.startsWith('@')) return _resolveToken(spec, palette);
  return palette.primary;
}

/// Whether [spec] is a theme token (vs a hex literal).
bool isThemeToken(String spec) => spec.startsWith('@');

Color? _parseHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

final _tokenRegex =
    RegExp(r'^presetThemeColor(\w+?)(Darker|Lighter)?(\d+)?$');

Color _resolveToken(String token, AppColors p) {
  final stripped = token.substring(1); // drop leading '@'
  final m = _tokenRegex.firstMatch(stripped);
  if (m == null) return p.primary;

  final base = _baseColor(m.group(1)!, p);
  final shadeOp = m.group(2);
  if (shadeOp == null) return base;

  final amountPct = int.tryParse(m.group(3) ?? '') ?? 20;
  final t = (amountPct.clamp(0, 100)) / 100.0;
  return shadeOp == 'Darker'
      ? Color.lerp(base, Colors.black, t)!
      : Color.lerp(base, Colors.white, t)!;
}

Color _baseColor(String name, AppColors p) {
  return switch (name) {
    '1' => p.primary,
    '2' => p.secondary,
    '3' => p.info, // AppColors has no tertiary; info is the third accent
    'Container' => p.primaryContainer,
    'OnIcon' => p.onPrimary,
    'Border' => p.outline,
    _ => p.primary,
  };
}
