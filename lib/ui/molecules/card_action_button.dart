import 'package:flutter/material.dart';

import '../tokens/app/app_colors.dart';

/// The ONE standard top-right action of a summary card AND a detail hero
/// (owner 2026-10-16): a round outlined icon button, the one control height
/// (40), next to the 👁. A hero's ✏️ is this with the edit icon.
/// List pages put the 🔍 toggle here ([ToolbarToggleButton] is this with
/// the toolbar state wired in).
///
/// - [selected]: filled tint + teal ring (the toggled-on look).
/// - [showDot]: a red dot on the corner — "something is active behind this".
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.selected = false,
    this.showDot = false,
    super.key,
  });

  /// Tap target / circle diameter.
  static const double size = 40;

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool selected;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final button = Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            if (showDot)
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    key: const ValueKey('cardActionDot'),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: palette.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
