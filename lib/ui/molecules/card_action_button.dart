import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../tokens/app/app_colors.dart';

class CardActionButton extends StatelessWidget {
  const CardActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.selected = false,
    this.showDot = false,
    super.key,
  });

  static const double size = AppIconButton.sizeHero;

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool selected;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final size = AppIconButton.resolveSize(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppIconButton(
            icon: icon,
            onPressed: onTap,
            tooltip: tooltip,
            selected: selected,
          ),
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
    );
  }
}
