import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// `‹  label ▾  ›` — [MonthPill]'s look for any period (a week, a year,
/// a custom range, "ทั้งหมด"). The arrows step [onPrev] / [onNext]; a null
/// one is shown dimmed, and both null hides them (a period with no
/// neighbours, like ทั้งหมด). Tapping the label calls [onTap] (e.g. open
/// the filter sheet at its period section).
class PeriodPill extends StatelessWidget {
  const PeriodPill({
    required this.label,
    this.onPrev,
    this.onNext,
    this.onTap,
    this.prevTooltip,
    this.nextTooltip,
    super.key,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTap;
  final String? prevTooltip;
  final String? nextTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arrows = onPrev != null || onNext != null;

    Widget step(IconData icon, String? tooltip, VoidCallback? onStep) {
      final button = InkResponse(
        onTap: onStep,
        radius: 20,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(
            icon,
            size: 20,
            color: onStep == null
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
        ),
      );
      return tooltip == null
          ? button
          : Tooltip(message: tooltip, child: button);
    }

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 1.5,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrows) step(AppIcons.chevronLeft, prevTooltip, onPrev),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: arrows ? AppSpacing.xs : AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      AppIcons.dropdown,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
          if (arrows) step(AppIcons.chevronRight, nextTooltip, onNext),
        ],
      ),
    );
  }
}
