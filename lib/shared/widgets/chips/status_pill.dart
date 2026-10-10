import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import 'pill.dart';
import 'tone.dart';

/// Status pill — `● label` in a [tone] ("● ใช้งาน", "ค้างอยู่"). The
/// status role of the pill family (see [PillSize]); `ProjectStatusPill`
/// and every page's status are this.
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
    this.size,
    super.key,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  /// Leading coloured dot (ignored when [icon] is set).
  final bool showDot;
  final VoidCallback? onTap;

  /// Shorthand for [PillSize.small] — list rows.
  final bool dense;

  /// Overrides [dense]. Default [PillSize.medium].
  final PillSize? size;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context);
    final s = size ?? (dense ? PillSize.small : PillSize.medium);
    return PillShell(
      size: s,
      background: color.withValues(alpha: 0.14),
      onTap: onTap,
      child: PillContent(
        label: label,
        color: color,
        size: s,
        leading: icon != null
            ? Icon(icon, size: s.icon, color: color)
            : showDot
            ? Container(
                width: s.dot,
                height: s.dot,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : null,
        trailing: onTap == null
            ? null
            : Icon(AppIcons.expand, size: s.icon + 2, color: color),
      ),
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
