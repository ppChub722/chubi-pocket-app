import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../atoms/shown_tween_builder.dart';

class DonutSegment {
  const DonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

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
    final shown = segments.where((s) => s.value > 0).toList();
    return SizedBox.square(
      dimension: size,
      child: ShownTweenBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => CustomPaint(
          painter: _DonutPainter(
            segments: shown,
            thickness: thickness,
            track: scheme.surfaceContainerHighest,
            gapColor:
                Theme.of(context).cardTheme.color ?? scheme.surfaceContainerLow,
            grown: t,
          ),
          child: child,
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
    this.grown = 1,
  });

  final List<DonutSegment> segments;
  final double thickness;
  final Color track;
  final Color gapColor;

  /// 0 → 1 while the ring fills in.
  final double grown;

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
    if (grown < 1) {
      canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = track);
    }
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = s.value / total * math.pi * 2 * grown;
      canvas.drawArc(rect, start, sweep, false, stroke..color = s.color);
      start += sweep;
    }
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
        a += s.value / total * math.pi * 2 * grown;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.track != track ||
      old.gapColor != gapColor ||
      old.grown != grown;
}
