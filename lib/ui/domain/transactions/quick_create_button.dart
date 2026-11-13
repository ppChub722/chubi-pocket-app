import 'package:flutter/material.dart';

import '../tokens/app_icons.dart';
import '../tokens/quick_create_mode.dart';
import '../../app_aliases.dart';

/// The mode's glyph: the record glyph for a transaction, the debt / saving
/// module icons.
IconData quickCreateModeIcon(QuickCreateMode mode) => switch (mode) {
  QuickCreateMode.tx => AppIcons.record,
  QuickCreateMode.debt => AppIcons.debt,
  QuickCreateMode.saving => AppIcons.savings,
};

/// The shell's centre create button (owner 2026-11-12): a round button, no
/// ring, glowing evenly in its colour; the page's icon with its [label] (the
/// word) under it. The nav draws the bar's own shape round it.
class QuickCreateButton extends StatelessWidget {
  const QuickCreateButton({
    required this.onPressed,
    this.mode = QuickCreateMode.tx,
    this.size = diameter,
    this.label,
    this.tooltip,
    this.color,
    this.icon,
    super.key,
  });

  final VoidCallback onPressed;
  final QuickCreateMode mode;

  final double size;
  final String? label;
  final String? tooltip;

  /// A page's own create action (an event's "เพิ่มบิล" in its tint): this
  /// colour and [icon] instead of the mode's.
  final Color? color;
  final IconData? icon;

  static const double diameter = 72;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fill = color ?? QuickCreateModeColors.of(context, mode);
    final on = color != null
        ? AppChip.readableOn(color!)
        : QuickCreateModeColors.onOf(context, mode);
    final label = this.label;
    final glyph = icon ?? quickCreateModeIcon(mode);
    final button = SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: fill),
        duration: still ? Duration.zero : AppDurations.fast,
        curve: Curves.easeOutCubic,
        builder: (context, color, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (color ?? fill).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: label == null
                    ? AppIcon(glyph, size: AppIconSize.xl, color: on)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        // A long word shrinks rather than leaving the circle.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(glyph, size: 26, color: on),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                key: const ValueKey('quickCreateLabel'),
                                maxLines: 1,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: on,
                                  fontSize: 11.5,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// The + in a list's head (mock QuickCreateBtn "ปุ่ม + ในหน้า"): a round
/// button level with its row's other actions, the + and the ring in the
/// page's mode colour. Opens quick create in that mode.
class QuickCreateHeadButton extends StatelessWidget {
  const QuickCreateHeadButton({
    required this.mode,
    required this.onPressed,
    this.tooltip,
    this.size,
    super.key,
  });

  final QuickCreateMode mode;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = QuickCreateModeColors.of(context, mode);
    final side = AppIconButton.resolveSize(context, size);
    final button = SizedBox.square(
      dimension: side,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: CircleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: AppIcon(AppIcons.add, size: AppIconSize.md, color: color),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// The empty state's call to action (mock QuickCreateBtn "ตอนยังไม่มีข้อมูล"):
/// a filled [AppButton] in the page's mode colour, + and the word.
class QuickCreateCtaButton extends StatelessWidget {
  const QuickCreateCtaButton({
    required this.mode,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final QuickCreateMode mode;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = QuickCreateModeColors.of(context, mode);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: color,
          onPrimary: QuickCreateModeColors.onOf(context, mode),
        ),
      ),
      child: AppButton(
        label: label,
        icon: AppIcons.add,
        size: AppButtonSize.control,
        onPressed: onPressed,
      ),
    );
  }
}
