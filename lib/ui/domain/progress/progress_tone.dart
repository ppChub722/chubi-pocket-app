import 'package:flutter/material.dart';

import '../../tokens/app/app_colors.dart';

/// How a progress bar (a budget, a saving goal) is coloured — decided by the
/// caller (for budgets the BE sends it: neutral / warning / danger), never
/// derived from the ratio here.
enum ProgressTone {
  /// The entity's own tint (its icon colour), else the primary colour.
  neutral,

  /// Close to the limit.
  warning,

  /// Past the limit.
  danger,

  /// Reached (a finished goal).
  success,

  /// Stopped / archived — grey.
  muted;

  /// The bar / text colour. [entityTint] is what [neutral] resolves to
  /// (`iconCode.tintFor(palette)`).
  Color resolve(BuildContext context, {Color? entityTint}) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return switch (this) {
      ProgressTone.neutral => entityTint ?? scheme.primary,
      ProgressTone.warning => palette.warning,
      ProgressTone.danger => palette.error,
      ProgressTone.success => palette.success,
      ProgressTone.muted => scheme.onSurfaceVariant,
    };
  }
}
