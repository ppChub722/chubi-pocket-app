import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// One slice of a [SegmentedBar].
class BarSegment {
  const BarSegment({required this.value, required this.color, this.label});

  /// Its share (any positive number; the bar normalises them).
  final double value;
  final Color color;

  /// The legend text ([SegmentedBar.legend]).
  final String? label;
}

/// A thin proportion bar split into coloured segments (the wallets summary:
/// how the total divides by type), optionally with a [LegendDot] row under it.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    required this.segments,
    this.height = 8,
    this.legend = false,
    super.key,
  });

  final List<BarSegment> segments;
  final double height;

  /// A wrapping row of dot + label under the bar (the segments' labels).
  final bool legend;

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final s in segments)
        if (s.value > 0) s,
    ];
    final scheme = Theme.of(context).colorScheme;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: shown.isEmpty
            ? ColoredBox(color: scheme.surfaceContainerHighest)
            : Row(
                children: [
                  for (final s in shown)
                    Expanded(
                      flex: (s.value * 1000).round().clamp(1, 1 << 30),
                      child: ColoredBox(color: s.color),
                    ),
                ],
              ),
      ),
    );
    if (!legend) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        const SizedBox(height: PpForgeSpacing.sm),
        Wrap(
          spacing: PpForgeSpacing.md,
          runSpacing: PpForgeSpacing.xs,
          children: [
            for (final s in shown)
              if (s.label != null) LegendDot(color: s.color, label: s.label!),
          ],
        ),
      ],
    );
  }
}

/// A colour dot with a label — a chart or bar legend entry.
class LegendDot extends StatelessWidget {
  const LegendDot({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(PpForgeRadius.sm),
        ),
      ),
      const SizedBox(width: PpForgeSpacing.xs),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
