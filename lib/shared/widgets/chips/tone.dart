import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Semantic colour of a pill / badge / snackbar. Resolved from the active
/// theme's [AppColors] so every theme keeps its own palette.
enum Tone { neutral, primary, success, warning, danger, info, income, expense }

extension ToneColor on Tone {
  Color color(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      Tone.neutral => scheme.onSurfaceVariant,
      Tone.primary => palette.primary,
      Tone.success => palette.success,
      Tone.warning => palette.warning,
      Tone.danger => palette.error,
      Tone.info => palette.info,
      Tone.income => palette.income,
      Tone.expense => palette.expense,
    };
  }
}
