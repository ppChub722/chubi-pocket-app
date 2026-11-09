import 'package:flutter/material.dart';

import '../../atoms/busy_scope.dart';
import '../../molecules/option_menu.dart';
import '../../molecules/selectable_frame.dart';
import '../../tokens/pp_forge_icons.dart';
import 'icon_registry.dart';
import '../../app_aliases.dart';

class IconSwatchGrid extends StatelessWidget {
  const IconSwatchGrid({
    required this.glyphs,
    required this.selected,
    required this.onToggle,
    this.onClear,
    this.clearLabel,
    this.fallback = PpForgeIcons.category,
    this.size = 32,
    super.key,
  });

  final List<String> glyphs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  final VoidCallback? onClear;
  final String? clearLabel;

  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final grid = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final g in glyphs)
          BusyLock(
            child: InkResponse(
              onTap: () => onToggle(g),
              radius: size / 2 + 6,
              child: SelectableFrame(
                selected: selected.contains(g),
                radius: size / 2,
                gap: 2,
                child: AppAvatar.icon(
                  IconRegistry.get(g, fallback: fallback),
                  size: size,
                ),
              ),
            ),
          ),
      ],
    );
    if (onClear == null || selected.isEmpty) return grid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        PopoverClearItem(label: clearLabel, onPressed: onClear!),
      ],
    );
  }
}
