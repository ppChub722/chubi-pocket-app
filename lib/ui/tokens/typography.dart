import 'package:flutter/material.dart';

/// The seven text roles of the app (owner 2026-10-12). A role says what the
/// text IS; the theme decides how it looks (font, size, weight), so a theme
/// change re-types the whole app. Features never pick a `textTheme.*` slot
/// by hand — they use a role ([PpForgeTypography.of], or the `PpForgeText` atom).
enum PpForgeTextRole {
  /// A big number or heading on its own — a hero's amount, a screen number.
  display,

  /// A page or hero title.
  title,

  /// The big green heading of a detail section ("หัวข้อ section").
  section,

  /// A row's field label ("หัวข้อ").
  label,

  /// Running text and values.
  body,

  /// Small supporting text, muted — hints, meta lines, captions.
  caption,

  /// An amount of money: bold, tabular digits.
  money,
}

/// Role → [TextStyle], from the active theme's text theme.
abstract final class PpForgeTypography {
  static TextStyle? of(BuildContext context, PpForgeTextRole role) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final scheme = theme.colorScheme;
    return switch (role) {
      PpForgeTextRole.display => t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      PpForgeTextRole.title => t.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      PpForgeTextRole.section => t.labelLarge?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      PpForgeTextRole.label => t.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      PpForgeTextRole.body => t.bodyLarge,
      PpForgeTextRole.caption => t.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      PpForgeTextRole.money => t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    };
  }
}
