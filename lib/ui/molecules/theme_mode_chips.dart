import 'package:flutter/material.dart';

import '../tokens/pp_forge_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_chip.dart';

class ThemeModeChips extends StatelessWidget {
  const ThemeModeChips({
    required this.selected,
    required this.onChanged,
    required this.lightLabel,
    required this.darkLabel,
    required this.systemLabel,
    super.key,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;
  final String lightLabel;
  final String darkLabel;
  final String systemLabel;

  @override
  Widget build(BuildContext context) {
    final items = [
      (ThemeMode.light, PpForgeIcons.lightMode, lightLabel),
      (ThemeMode.dark, PpForgeIcons.darkMode, darkLabel),
      (ThemeMode.system, PpForgeIcons.systemMode, systemLabel),
    ];
    return Wrap(
      spacing: PpForgeSpacing.sm,
      runSpacing: PpForgeSpacing.sm,
      children: [
        for (final (mode, icon, label) in items)
          PpForgeChip(
            label: label,
            icon: icon,
            selected: mode == selected,
            onTap: () => onChanged(mode),
          ),
      ],
    );
  }
}
