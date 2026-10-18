import 'package:flutter/material.dart';

enum AppTextRole { display, title, section, label, body, caption, money }

abstract final class AppTypography {
  static TextStyle? of(BuildContext context, AppTextRole role) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final scheme = theme.colorScheme;
    return switch (role) {
      AppTextRole.display => t.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      AppTextRole.title => t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      AppTextRole.section => t.labelLarge?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      AppTextRole.label => t.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
      AppTextRole.body => t.bodyLarge,
      AppTextRole.caption => t.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      AppTextRole.money => t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    };
  }
}
