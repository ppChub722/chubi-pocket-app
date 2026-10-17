import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class BarSegment {
  const BarSegment({required this.value, required this.color, this.label});

  final double value;
  final Color color;

  final String? label;
}

class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    required this.segments,
    this.height = 8,
    this.legend = false,
    super.key,
  });

  final List<BarSegment> segments;
  final double height;

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
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in shown)
              if (s.label != null) LegendDot(color: s.color, label: s.label!),
          ],
        ),
      ],
    );
  }
}

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
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
