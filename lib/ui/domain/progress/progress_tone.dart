import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';

enum ProgressTone {
  neutral,

  normal,

  warning,

  danger,

  success,

  muted;

  Color resolve(BuildContext context, {Color? entityTint}) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    return switch (this) {
      ProgressTone.neutral => entityTint ?? scheme.primary,
      ProgressTone.normal => scheme.primary,
      ProgressTone.warning => palette.warning,
      ProgressTone.danger => palette.error,
      ProgressTone.success => palette.success,
      ProgressTone.muted => scheme.onSurfaceVariant,
    };
  }
}
