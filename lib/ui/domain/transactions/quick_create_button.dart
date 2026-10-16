import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../tokens/app/app_icons.dart';
import '../tokens/quick_create_mode.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/icon_size.dart';

/// The shell's centre `+` (owner 2026-10-12): a big filled circle wrapped in
/// a page-coloured ring, so it reads as punched through the bottom bar. Its
/// fill is the [mode]'s colour ([QuickCreateModeColors]) — the mode the
/// quick create will open in on the page on screen — and a change of mode
/// (tab switch, push, pop) cross-fades over [PpForgeDurations.fast].
class QuickCreateButton extends StatelessWidget {
  const QuickCreateButton({
    required this.onPressed,
    this.mode = QuickCreateMode.tx,
    this.size = 76,
    this.tooltip,
    super.key,
  });

  final VoidCallback onPressed;
  final QuickCreateMode mode;

  /// Outer diameter, ring included.
  final double size;
  final String? tooltip;

  static const double _ring = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fill = QuickCreateModeColors.of(context, mode);
    final on = QuickCreateModeColors.onOf(context, mode);
    final button = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: fill),
        duration: still ? Duration.zero : PpForgeDurations.fast,
        curve: Curves.easeOutCubic,
        builder: (context, color, _) => Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: color?.withValues(alpha: 0.6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: PpForgeIcon(
                PpForgeIcons.add,
                size: PpForgeIconSize.xl,
                color: on,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
