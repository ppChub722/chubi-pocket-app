import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colour of each feature **group** — the เพิ่มเติม hub's sections
/// (คลัง / คน / วางแผน). Every card in a group shares its group's colour.
///
/// Kept apart from [AppColors] on purpose: those are *semantic* colours
/// (income, expense, error …); these only mark "which part of the app".
/// Each [AppTheme] ships its own set (light + dark) in its own family —
/// warm pinks for Sweet, cool greens / blues for Mint. A theme without a
/// set falls back to its primary colour everywhere ([of]).
@immutable
class ModuleColors extends ThemeExtension<ModuleColors> {
  const ModuleColors({
    required this.library,
    required this.people,
    required this.planning,
  });

  /// คลัง — categories, tags.
  final Color library;

  /// คน — contacts, projects, personal debts.
  final Color people;

  /// วางแผน — budgets, saving goals, scheduled transactions.
  final Color planning;

  /// The active theme's set, or every group in the theme's primary colour
  /// when the theme defines none.
  static ModuleColors of(BuildContext context) {
    final theme = Theme.of(context);
    final set = theme.extension<ModuleColors>();
    if (set != null) return set;
    final primary =
        theme.extension<AppColors>()?.primary ?? theme.colorScheme.primary;
    return ModuleColors(library: primary, people: primary, planning: primary);
  }

  @override
  ModuleColors copyWith({Color? library, Color? people, Color? planning}) =>
      ModuleColors(
        library: library ?? this.library,
        people: people ?? this.people,
        planning: planning ?? this.planning,
      );

  @override
  ModuleColors lerp(ModuleColors? other, double t) {
    if (other == null) return this;
    return ModuleColors(
      library: Color.lerp(library, other.library, t)!,
      people: Color.lerp(people, other.people, t)!,
      planning: Color.lerp(planning, other.planning, t)!,
    );
  }
}
