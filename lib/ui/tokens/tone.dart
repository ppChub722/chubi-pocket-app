import 'package:flutter/material.dart';

import 'app/app_colors.dart';

enum Tone { neutral, primary, success, warning, danger, info }

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
    };
  }
}
