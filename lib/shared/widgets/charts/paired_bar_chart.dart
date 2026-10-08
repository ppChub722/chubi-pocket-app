import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One x-axis group of a [PairedBarChart] — two values side by side
/// (e.g. income vs expense for a month).
class BarPair {
  const BarPair({required this.label, required this.a, required this.b});

  final String label;
  final double a;
  final double b;
}

/// Small grouped bar chart: per group two thin bars (colour [colorA] /
/// [colorB]) on one shared zero baseline, rounded at the data end, 2px
/// apart. No y-axis — it's a glance at the shape; exact values come from
/// tapping a group ([onSelect]) and showing them elsewhere.
///
/// The [selected] group stays full-strength, the others fade back so
/// the pick reads clearly. Pair it with a legend for [colorA] / [colorB].
class PairedBarChart extends StatelessWidget {
  const PairedBarChart({
    required this.groups,
    required this.colorA,
    required this.colorB,
    this.selected,
    this.onSelect,
    this.height = 96,
    super.key,
  });

  final List<BarPair> groups;
  final Color colorA;
  final Color colorB;
  final int? selected;
  final ValueChanged<int>? onSelect;

  /// Plot height, excluding the label row.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final maxV = groups.fold<double>(
      0,
      (m, g) => math.max(m, math.max(g.a, g.b)),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < groups.length; i++)
          Expanded(
            // The whole column is the hit target, not just the bars.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelect == null ? null : () => onSelect!(i),
              child: Opacity(
                opacity: selected == null || selected == i ? 1 : 0.4,
                child: Column(
                  children: [
                    SizedBox(
                      height: height,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _PairPainter(
                          a: maxV == 0 ? 0 : groups[i].a / maxV,
                          b: maxV == 0 ? 0 : groups[i].b / maxV,
                          colorA: colorA,
                          colorB: colorB,
                          baseline: scheme.outlineVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      groups[i].label,
                      style: selected == i
                          ? labelStyle?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            )
                          : labelStyle,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PairPainter extends CustomPainter {
  _PairPainter({
    required this.a,
    required this.b,
    required this.colorA,
    required this.colorB,
    required this.baseline,
  });

  /// 0..1 of the chart's max.
  final double a;
  final double b;
  final Color colorA;
  final Color colorB;
  final Color baseline;

  static const _barWidth = 8.0;
  static const _gap = 2.0;
  static const _radius = Radius.circular(4);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height;
    void bar(double left, double v, Color c) {
      if (v <= 0) return;
      // Never thinner than the cap so a tiny value still reads as "some".
      final h = math.max(v * size.height, 3.0);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, bottom - h, _barWidth, h),
          topLeft: _radius,
          topRight: _radius,
        ),
        Paint()..color = c,
      );
    }

    bar(cx - _gap / 2 - _barWidth, a, colorA);
    bar(cx + _gap / 2, b, colorB);
    canvas.drawLine(
      Offset(0, bottom - 0.5),
      Offset(size.width, bottom - 0.5),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PairPainter old) =>
      old.a != a ||
      old.b != b ||
      old.colorA != colorA ||
      old.colorB != colorB ||
      old.baseline != baseline;
}
