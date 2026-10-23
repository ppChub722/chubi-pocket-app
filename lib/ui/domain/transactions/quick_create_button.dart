import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_chip.dart';
import '../../atoms/app_icon.dart';
import '../../atoms/app_icon_button.dart';
import '../../tokens/app/app_icons.dart';
import '../../tokens/app/quick_create_mode.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/icon_size.dart';

/// The mode's glyph (mock QuickCreateBtn): + for a transaction, the debt /
/// saving module icons.
IconData quickCreateModeIcon(QuickCreateMode mode) => switch (mode) {
  QuickCreateMode.tx => AppIcons.add,
  QuickCreateMode.debt => AppIcons.debt,
  QuickCreateMode.saving => AppIcons.savings,
};

/// The shell's centre create button. With a [label] (owner 2026-10-22, mock
/// QuickCreateBtn) it is a [capsuleHeight] capsule — the mode's icon + the
/// word (บันทึก / จดหนี้ / ออมเงิน) in the mode's colour; without, the round +.
class QuickCreateButton extends StatelessWidget {
  const QuickCreateButton({
    required this.onPressed,
    this.mode = QuickCreateMode.tx,
    this.size = 76,
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

  static const double _ring = 4;
  static const double capsuleHeight = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final fill = color ?? QuickCreateModeColors.of(context, mode);
    final on = color != null
        ? AppChip.readableOn(color!)
        : QuickCreateModeColors.onOf(context, mode);
    final label = this.label;
    final Widget button;
    if (label != null) {
      button = TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: fill),
        duration: still ? Duration.zero : AppDurations.fast,
        curve: Curves.easeOutCubic,
        builder: (context, color, _) => SizedBox(
          height: capsuleHeight,
          child: Material(
            color: color,
            shape: const StadiumBorder(),
            elevation: 4,
            shadowColor: color?.withValues(alpha: 0.35),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 16, 0),
                // A long word shrinks rather than breaking the bar.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        icon ?? quickCreateModeIcon(mode),
                        size: AppIconSize.lg,
                        color: on,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        key: const ValueKey('quickCreateLabel'),
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: on,
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
      );
    } else {
      button = Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(_ring),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fill),
          duration: still ? Duration.zero : AppDurations.fast,
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
                child: AppIcon(AppIcons.add, size: AppIconSize.xl, color: on),
              ),
            ),
          ),
        ),
      );
    }
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
