import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Up to [maxVisible] round icons overlapping, then the total [count]: a
/// list's summary where names would be cut off (a budget's categories /
/// wallets). [tooltip] spells out what the icons stand for.
class IconStackCount extends StatelessWidget {
  const IconStackCount({
    required this.icons,
    required this.count,
    this.tooltip,
    this.size = 24,
    this.maxVisible = 3,
    super.key,
  });

  /// Each is drawn in a [size] × [size] box.
  final List<Widget> icons;
  final int count;
  final String? tooltip;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = icons.take(maxVisible).toList();
    final step = size * 0.7;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown.isNotEmpty) ...[
          SizedBox(
            width: (shown.length - 1) * step + size,
            height: size,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * step,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
                      ),
                      child: SizedBox.square(dimension: size, child: shown[i]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final t = tooltip;
    return t == null ? row : Tooltip(message: t, child: row);
  }
}
