import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class ModuleColors extends ThemeExtension<ModuleColors> {
  const ModuleColors({
    required this.library,
    required this.people,
    required this.planning,
    this.debt = defaultDebt,
    this.saving = defaultSaving,
  });

  /// The create-mode colours (owner 2026-10-22, mock QuickCreateBtn): จดหนี้
  /// purple, ออมเงิน blue — the same in every theme unless one overrides.
  static const Color defaultDebt = Color(0xFF7A5AE0);
  static const Color defaultSaving = Color(0xFF3B7DD8);

  final Color library;

  final Color people;

  final Color planning;

  /// Debt mode (the centre button, the in-page + and CTA).
  final Color debt;

  /// Saving mode.
  final Color saving;

  static ModuleColors of(BuildContext context) {
    final theme = Theme.of(context);
    final set = theme.extension<ModuleColors>();
    if (set != null) return set;
    final primary =
        theme.extension<AppColors>()?.primary ?? theme.colorScheme.primary;
    return ModuleColors(library: primary, people: primary, planning: primary);
  }

  @override
  ModuleColors copyWith({
    Color? library,
    Color? people,
    Color? planning,
    Color? debt,
    Color? saving,
  }) => ModuleColors(
    library: library ?? this.library,
    people: people ?? this.people,
    planning: planning ?? this.planning,
    debt: debt ?? this.debt,
    saving: saving ?? this.saving,
  );

  @override
  ModuleColors lerp(ModuleColors? other, double t) {
    if (other == null) return this;
    return ModuleColors(
      library: Color.lerp(library, other.library, t)!,
      people: Color.lerp(people, other.people, t)!,
      planning: Color.lerp(planning, other.planning, t)!,
      debt: Color.lerp(debt, other.debt, t)!,
      saving: Color.lerp(saving, other.saving, t)!,
    );
  }
}
