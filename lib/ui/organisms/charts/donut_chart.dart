import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  const DonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

/// Ring chart — share of a whole (e.g. expense by category). Slices run
/// clockwise from 12 o'clock with a thin surface gap between them; an
/// empty or all-zero list draws a neutral track.
///
/// Identity lives in a legend next to it (colour is never the only cue);
/// [center] usually holds the total.
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.segments,
    this.size = 120,
    this.thickness = 14,
    this.center,
    super.key,
  });

  final List<DonutSegment> segments;
  final double size;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: segments.where((s) => s.value > 0).toList(),
          thickness: thickness,
          track: scheme.surfaceContainerHighest,
          // Gaps take the card's colour — the chart normally sits on one.
          gapColor:
              Theme.of(context).cardTheme.color ?? scheme.surfaceContainerLow,
        ),
        child: center == null
            ? null
            : Center(
                child: Padding(
                  padding: EdgeInsets.all(thickness + 4),
                  child: FittedBox(fit: BoxFit.scaleDown, child: center),
                ),
              ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.track,
    required this.gapColor,
  });

  final List<DonutSegment> segments;
  final double thickness;
  final Color track;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final total = segments.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = track);
      return;
    }
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = s.value / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, stroke..color = s.color);
      start += sweep;
    }
    // 2px surface spokes at each boundary — slices stay distinct even
    // when neighbouring hues are close.
    if (segments.length > 1) {
      final c = size.center(Offset.zero);
      final outer = size.shortestSide / 2;
      final gap = Paint()
        ..color = gapColor
        ..strokeWidth = 2;
      var a = -math.pi / 2;
      for (final s in segments) {
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          c + dir * (outer - thickness - 1),
          c + dir * (outer + 1),
          gap,
        );
        a += s.value / total * math.pi * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.track != track ||
      old.gapColor != gapColor;
}
