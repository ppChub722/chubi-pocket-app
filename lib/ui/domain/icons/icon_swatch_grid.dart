import 'package:flutter/material.dart';

import '../../atoms/app_avatar.dart';
import '../../molecules/option_menu.dart';
import '../../molecules/selectable_frame.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'icon_registry.dart';

/// Icon-swatch grid for [PopoverAnchor] — the [ColorSwatchGrid] of glyphs
/// (an icon filter): multi-select circles by icon id, ring-highlighted when
/// picked, + the same "ล้าง" row once something is selected ([onClear]).
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

  /// Icon ids ([IconRegistry] keys).
  final List<String> glyphs;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Clears the selection; null hides the "ล้าง" row.
  final VoidCallback? onClear;
  final String? clearLabel;

  /// Shown for an id the registry doesn't know.
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final grid = Wrap(
      spacing: PpForgeSpacing.sm,
      runSpacing: PpForgeSpacing.sm,
      children: [
        for (final g in glyphs)
          InkResponse(
            onTap: () => onToggle(g),
            radius: size / 2 + 6,
            child: SelectableFrame(
              selected: selected.contains(g),
              radius: size / 2,
              gap: 2,
              child: PpForgeAvatar.icon(
                IconRegistry.get(g, fallback: fallback),
                size: size,
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
