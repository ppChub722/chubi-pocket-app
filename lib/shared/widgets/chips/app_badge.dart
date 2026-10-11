import 'package:flutter/material.dart';

import 'tone.dart';

/// Small rectangular label — roles, "ไม่มีกระเป๋า", counts. Quieter than a
/// status [AppChip] (no dot, tighter radius, a counter-sized label).
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
