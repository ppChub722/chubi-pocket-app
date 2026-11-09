import 'package:flutter/material.dart';

enum PpForgeTextRole { display, title, section, label, body, caption, money }

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
      PpForgeTextRole.title => t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
