import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class ModuleColors extends ThemeExtension<ModuleColors> {
  const ModuleColors({
    required this.library,
    required this.people,
    required this.planning,
  });

  final Color library;

  final Color people;

  final Color planning;

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
