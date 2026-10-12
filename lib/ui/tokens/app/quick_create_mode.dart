import 'package:flutter/material.dart';

import 'module_colors.dart';

/// What the quick create opens as (owner 2026-10-12: ONE sheet, opened with
/// a per-page default).
enum QuickCreateMode {
  /// A transaction (expense / income / transfer).
  tx,

  /// A debt entry with a person (Paid / Received).
  debt,

  /// A saving entry: money set aside from a wallet into the spare pool or a
  /// goal (owner 2026-10-13; never a real transaction).
  saving,
}

/// THE colour of each quick create mode — the ONE mapping (owner
/// 2026-10-12): the shell's centre + and the quick create's mode chips take
/// it from here; pages never pass a colour.
///
/// - [QuickCreateMode.tx] = the theme's primary
/// - [QuickCreateMode.debt] = the people module colour ([ModuleColors.people])
/// - [QuickCreateMode.saving] = the planning module colour
///   ([ModuleColors.planning])
abstract final class QuickCreateModeColors {
  /// The mode's fill colour.
  static Color of(BuildContext context, QuickCreateMode mode) => switch (mode) {
    QuickCreateMode.tx => Theme.of(context).colorScheme.primary,
    QuickCreateMode.debt => ModuleColors.of(context).people,
    QuickCreateMode.saving => ModuleColors.of(context).planning,
  };

  /// What sits on [of] (the + glyph, a selected chip's label).
  static Color onOf(BuildContext context, QuickCreateMode mode) =>
      switch (mode) {
        QuickCreateMode.tx => Theme.of(context).colorScheme.onPrimary,
        QuickCreateMode.debt ||
        QuickCreateMode.saving => onFill(of(context, mode)),
      };

  /// Black or white, whichever reads on [fill].
  static Color onFill(Color fill) =>
      ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
