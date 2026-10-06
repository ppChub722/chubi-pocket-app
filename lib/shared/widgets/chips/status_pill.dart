import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import 'tone.dart';

/// Rounded status pill ("● ใช้งาน", "ค้างอยู่", "เจ้าของ").
///
/// Pass [onTap] to make it a picker trigger — it then shows a `⌄` and
/// should open `showStatusSheet` / `showOptionSheet`. Wrap in
/// `LockedInEdit` to disable it while the page is in edit mode.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.tone = Tone.neutral,
    this.icon,
    this.showDot = true,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  /// Leading coloured dot (ignored when [icon] is set).
  final bool showDot;
  final VoidCallback? onTap;

  /// Smaller paddings — for list rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context);
    final textStyle = (dense
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelLarge)
        ?.copyWith(color: color, fontWeight: FontWeight.w600);
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 2 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 16, color: color),
            const SizedBox(width: AppSpacing.xs),
          ] else if (showDot) ...[
            Container(
              width: dense ? 6 : 8,
              height: dense ? 6 : 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: textStyle),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(AppIcons.expand, size: dense ? 14 : 18, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: pill,
    );
  }
}

/// Small rectangular label — roles, "ไม่มีกระเป๋า", counts. Quieter than a
/// [StatusPill] (no dot, tighter radius).
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = Tone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neutral = tone == Tone.neutral;
    final fg = neutral ? scheme.onSurfaceVariant : tone.color(context);
    final bg = neutral
        ? scheme.surfaceContainerHighest
        : tone.color(context).withValues(alpha: 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
