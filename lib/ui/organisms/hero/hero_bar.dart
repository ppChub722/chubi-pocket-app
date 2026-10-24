import 'package:flutter/material.dart';

import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';

/// A hero's progress bar (a [ProgressRow]) or a split bar with a legend.
class HeroBar extends StatelessWidget {
  const HeroBar({
    required this.value,
    this.expected,
    this.marker,
    this.ticks = const [],
    this.alert,
    this.alertColor,
    this.markerLabel,
    this.alertLabel,
    this.color,
    this.overColor,
    this.fillLabel,
    this.fillDot = false,
    this.markerBubble,
    this.endLabel,
    this.left,
    this.right,
    this.height = 8,
    super.key,
  }) : parts = null;

  /// The parts side by side, a small left / right legend under them.
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
       alert = null,
       alertColor = null,
       markerLabel = null,
       alertLabel = null,
       color = null,
       overColor = null,
       fillLabel = null,
       fillDot = false,
       markerBubble = null,
       endLabel = null;

  final double value;
  final double? expected;
  final double? marker;
  final List<double> ticks;
  final double? alert;
  final Color? alertColor;
  final String? markerLabel;
  final String? alertLabel;
  final Color? color;
  final Color? overColor;

  /// The "31%" pill on the end of the fill ([ProgressRow.fillLabel]).
  final String? fillLabel;

  /// [ProgressRow.fillDot] / [ProgressRow.markerBubble] / [ProgressRow.endLabel].
  final bool fillDot;
  final String? markerBubble;
  final String? endLabel;
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
        alert: alert,
        alertColor: alertColor,
        markerLabel: markerLabel,
        alertLabel: alertLabel,
        color: color,
        overColor: overColor,
        fillLabel: fillLabel,
        fillDot: fillDot,
        markerBubble: markerBubble,
        endLabel: endLabel,
        height: height,
        label: left,
        trailing: right,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final caption = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: hero?.muted ?? scheme.onSurfaceVariant,
    );
    final used = split.fold<double>(0, (s, p) => s + p.$1).clamp(0.0, 1.0);
    final shown = [
      for (final p in split)
        if (p.$1 > 0) p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown.length < 2)
          _bar(context, split, used, hero, scheme)
        else
          _labelled(
            context,
            shown,
            _bar(context, split, used, hero, scheme),
            hero?.track ?? scheme.surfaceContainerHighest,
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

  /// Each part's share in a pill at its middle; a narrow part's pill
  /// overlaps its neighbours, kept inside the bar. A see-through part colour
  /// is laid on the track first, so its pill is solid like its segment.
  Widget _labelled(
    BuildContext context,
    List<(double, Color)> parts,
    Widget bar,
    Color track,
  ) {
    final pills = [
      for (final (ratio, c) in parts)
        ProgressRow.fillPill(
          context,
          '${(ratio * 100).round()}%',
          Color.alphaBlend(c, track),
          minHeight: height,
        ),
    ];
    final pillH = pills.fold<double>(height, (m, p) => p.$3 > m ? p.$3 : m);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        var start = 0.0;
        final placed = <Widget>[];
        for (final (i, (ratio, _)) in parts.indexed) {
          final segW = ratio.clamp(0.0, 1.0) * w;
          final (pill, pw, ph) = pills[i];
          placed.add(
            Positioned(
              left: (start + (segW - pw) / 2).clamp(
                0.0,
                (w - pw).clamp(0.0, double.infinity),
              ),
              top: (pillH - ph) / 2,
              child: pill,
            ),
          );
          start += segW;
        }
        return SizedBox(
          height: pillH,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: (pillH - height) / 2,
                child: bar,
              ),
              ...placed,
            ],
          ),
        );
      },
    );
  }

  Widget _bar(
    BuildContext context,
    List<(double, Color)> split,
    double used,
    HeroColors? hero,
    ColorScheme scheme,
  ) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: SizedBox(
      height: height,
      child: ColoredBox(
        color: hero?.track ?? scheme.surfaceContainerHighest,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (ratio, c) in split)
              if (ratio > 0)
                Expanded(
                  flex: (ratio.clamp(0.0, 1.0) * 1000).round().clamp(1, 1000),
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
  );
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
