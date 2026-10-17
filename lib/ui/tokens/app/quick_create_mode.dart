import 'package:flutter/material.dart';

import 'module_colors.dart';

enum QuickCreateMode {
  tx,

  debt,

  saving,
}

abstract final class QuickCreateModeColors {
  static Color of(BuildContext context, QuickCreateMode mode) => switch (mode) {
    QuickCreateMode.tx => Theme.of(context).colorScheme.primary,
    QuickCreateMode.debt => ModuleColors.of(context).people,
    QuickCreateMode.saving => ModuleColors.of(context).planning,
  };

  static Color onOf(BuildContext context, QuickCreateMode mode) =>
      switch (mode) {
        QuickCreateMode.tx => Theme.of(context).colorScheme.onPrimary,
        QuickCreateMode.debt ||
        QuickCreateMode.saving => onFill(of(context, mode)),
      };

  static Color onFill(Color fill) =>
      ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
