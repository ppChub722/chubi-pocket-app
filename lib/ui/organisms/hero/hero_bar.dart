import 'package:flutter/material.dart';

import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';

/// A hero's progress bar (a [ProgressRow]) or a split bar with a legend.
class HeroBar extends StatelessWidget {
  const HeroBar({
    required this.value,
    this.expected,
    this.marker,
    this.ticks = const [],
    this.color,
    this.overColor,
    this.left,
    this.right,
    this.height = 8,
    super.key,
  }) : parts = null;

  const HeroBar.split({
    required List<(double, Color)> this.parts,
    this.left,
    this.right,
    this.height = 8,
    super.key,
  }) : value = 0,
       expected = null,
       marker = null,
       ticks = const [],
       color = null,
       overColor = null;

  final double value;
  final double? expected;
  final double? marker;
  final List<double> ticks;
  final Color? color;
  final Color? overColor;
  final List<(double, Color)>? parts;

  final String? left;
  final String? right;
  final double height;

  @override
  Widget build(BuildContext context) {
    final split = parts;
    if (split == null) {
      return ProgressRow(
        value: value,
        expected: expected,
        marker: marker,
        ticks: ticks,
        color: color,
        overColor: overColor,
        height: height,
        label: left,
        trailing: right,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final caption = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final used = split.fold<double>(0, (s, p) => s + p.$1).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            height: height,
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (ratio, c) in split)
                    if (ratio > 0)
                      Expanded(
                        flex: (ratio.clamp(0.0, 1.0) * 1000).round().clamp(
                          1,
                          1000,
                        ),
                        child: ColoredBox(color: c),
                      ),
                  Expanded(
                    flex: ((1 - used) * 1000).round().clamp(0, 1000),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (left != null || right != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _Legend(
                    text: left ?? '',
                    dot: split.first.$2,
                    style: caption,
                  ),
                ),
                if (right != null)
                  _Legend(text: right!, dot: split.last.$2, style: caption),
              ],
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.text, required this.dot, required this.style});

  final String text;
  final Color dot;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    ],
  );
}

class HeroValueLine extends StatelessWidget {
  const HeroValueLine({required this.label, required this.value, super.key});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DefaultTextStyle.merge(
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          child: value,
        ),
      ],
    );
  }
}
