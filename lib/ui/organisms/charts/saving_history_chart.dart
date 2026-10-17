import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../atoms/skeleton_box.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/tone.dart';

/// Where [SavingHistoryChart] draws things inside its box — pure maths, so
/// the mapping is testable without painting.
///
/// X: slot `i` of [slots] spreads evenly between the plot's left and right
/// edge. Y: 0 at the bottom, `max(target, every value)` at the top.
class SavingChartGeometry {
  SavingChartGeometry({
    required this.size,
    required this.slots,
    required this.maxValue,
    this.padding = const EdgeInsets.fromLTRB(8, 16, 8, 22),
  });

  /// Builds the geometry for a series set: [slots] is the number of month
  /// positions (at least the points of actual + projection, at least 1).
  factory SavingChartGeometry.forSeries({
    required Size size,
    required List<double> actual,
    required List<double> projection,
    required double target,
    int? slots,
  }) {
    final n = math.max(slots ?? 0, actual.length + projection.length);
    var top = target.isFinite ? target : 0.0;
    for (final v in [...actual, ...projection]) {
      if (v.isFinite) top = math.max(top, v);
    }
    return SavingChartGeometry(
      size: size,
      slots: math.max(n, 1),
      maxValue: top > 0 ? top : 1,
    );
  }

  final Size size;
  final int slots;
  final double maxValue;
  final EdgeInsets padding;

  Rect get plot => Rect.fromLTRB(
    padding.left,
    padding.top,
    math.max(padding.left, size.width - padding.right),
    math.max(padding.top, size.height - padding.bottom),
  );

  double x(int slot) => slots <= 1
      ? plot.left
      : plot.left + plot.width * slot.clamp(0, slots - 1) / (slots - 1);

  double y(double value) {
    final v = value.isFinite ? value.clamp(0, maxValue).toDouble() : 0.0;
    return plot.bottom - plot.height * v / maxValue;
  }

  Offset point(int slot, double value) => Offset(x(slot), y(value));
}

/// Saving history of one goal (goals v2 mockup frame 2): the cumulative
/// saved amount per month, where the CURRENT pace leads, and what it would
/// take to make the deadline.
///
/// - [actual]: cumulative saved at each past month (solid, tone colour).
/// - [projection]: the months AFTER the last actual one at the real pace
///   (dashed, same colour, faded) — joins the last actual point.
/// - [showNeeded]: a dotted straight line from the last actual point to the
///   final slot at [target] — the pace the deadline needs.
/// - [target]: a dashed horizontal line (warning colour), labelled
///   [targetLabel] ("เป้า 80").
/// - [monthLabels]: one per slot (thinned to fit); slots =
///   `max(monthLabels.length, actual + projection)`.
/// - [tone] / [color]: the series colour (the goal's own, or warning when
///   behind).
///
/// Optional [caption] above and [actualLegend] / [neededLegend] under, as
/// plain strings. Everything is drawn by a `CustomPainter`; an empty series
/// draws only the baseline and target. `.skeleton` is the loading state.
class SavingHistoryChart extends StatelessWidget {
  const SavingHistoryChart({
    required this.actual,
    required this.target,
    this.projection = const [],
    this.showNeeded = true,
    this.monthLabels = const [],
    this.targetLabel,
    this.tone = Tone.info,
    this.color,
    this.caption,
    this.actualLegend,
    this.neededLegend,
    this.plan = const [],
    this.planLegend,
    this.height = 135,
    super.key,
  }) : _skeleton = false;

  const SavingHistoryChart.skeleton({this.height = 135, super.key})
    : actual = const [],
      projection = const [],
      target = 0,
      showNeeded = false,
      monthLabels = const [],
      targetLabel = null,
      tone = Tone.info,
      color = null,
      caption = null,
      actualLegend = null,
      neededLegend = null,
      plan = const [],
      planLegend = null,
      _skeleton = true;

  final List<double> actual;
  final List<double> projection;
  final double target;
  final bool showNeeded;
  final List<String> monthLabels;
  final String? targetLabel;
  final Tone tone;

  /// Overrides [tone] (the goal's own colour).
  final Color? color;
  final String? caption;
  final String? actualLegend;
  final String? neededLegend;

  /// The cumulative plan line, one per slot of [actual] (null = no plan that
  /// month). Drawn dashed in the muted colour; nothing when all are null.
  final List<double?> plan;
  final String? planLegend;
  final double height;
  final bool _skeleton;

  @override
  Widget build(BuildContext context) {
    if (_skeleton) {
      return SkeletonBox(height: height, borderRadius: 8);
    }
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final series = color ?? tone.color(context);
    final needed = Tone.success.color(context);
    final targetColor = Tone.warning.color(context);
    final small = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    Widget legend(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: ShapeDecoration(color: c, shape: const CircleBorder()),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: small),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null) ...[
          Text(caption!, style: small),
          const SizedBox(height: AppSpacing.xs),
        ],
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _SavingPainter(
              actual: actual,
              projection: projection,
              target: target,
              showNeeded: showNeeded,
              plan: plan,
              planColor: scheme.onSurfaceVariant,
              labels: monthLabels,
              targetLabel: targetLabel,
              seriesColor: series,
              neededColor: needed,
              targetColor: targetColor,
              gridColor: scheme.outlineVariant,
              labelStyle: small ?? const TextStyle(fontSize: 10),
            ),
          ),
        ),
        if (actualLegend != null ||
            neededLegend != null ||
            (planLegend != null && plan.any((v) => v != null))) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (actualLegend != null) legend(series, actualLegend!),
              if (neededLegend != null) legend(needed, neededLegend!),
              if (planLegend != null && plan.any((v) => v != null))
                legend(scheme.onSurfaceVariant, planLegend!),
            ],
          ),
        ],
      ],
    );
  }
}

class _SavingPainter extends CustomPainter {
  _SavingPainter({
    required this.actual,
    required this.projection,
    required this.target,
    required this.showNeeded,
    required this.plan,
    required this.planColor,
    required this.labels,
    required this.targetLabel,
    required this.seriesColor,
    required this.neededColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<double> actual;
  final List<double> projection;
  final double target;
  final bool showNeeded;
  final List<double?> plan;
  final Color planColor;
  final List<String> labels;
  final String? targetLabel;
  final Color seriesColor;
  final Color neededColor;
  final Color targetColor;
  final Color gridColor;
  final TextStyle labelStyle;

  void _dashed(Canvas canvas, Path path, Paint paint, double on, double off) {
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + on, m.length)), paint);
        d += on + off;
      }
    }
  }

  void _text(Canvas canvas, String s, Offset at, {bool center = true}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, center ? Offset(at.dx - tp.width / 2, at.dy) : at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = SavingChartGeometry.forSeries(
      size: size,
      actual: actual,
      projection: projection,
      target: target,
      slots: labels.length,
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Baseline + target.
    canvas.drawLine(
      Offset(g.plot.left, g.plot.bottom),
      Offset(g.plot.right, g.plot.bottom),
      line
        ..color = gridColor
        ..strokeWidth = 1,
    );
    if (target > 0) {
      final ty = g.y(target);
      _dashed(
        canvas,
        Path()
          ..moveTo(g.plot.left, ty)
          ..lineTo(g.plot.right, ty),
        line
          ..color = targetColor
          ..strokeWidth = 1,
        4,
        3,
      );
      if (targetLabel != null) {
        _text(
          canvas,
          targetLabel!,
          Offset(g.plot.left + 2, ty - 12),
          center: false,
        );
      }
    }

    // Plan (dashed, muted): runs of consecutive non-null points.
    var run = <Offset>[];
    void flushPlan() {
      if (run.length > 1) {
        _dashed(
          canvas,
          Path()..addPolygon(run, false),
          line
            ..color = planColor
            ..strokeWidth = 1.5,
          3,
          3,
        );
      }
      run = <Offset>[];
    }

    for (final (i, v) in plan.indexed) {
      if (v == null) {
        flushPlan();
      } else {
        run.add(g.point(i, v));
      }
    }
    flushPlan();

    // Actual (solid).
    final pts = [for (final (i, v) in actual.indexed) g.point(i, v)];
    if (pts.length > 1) {
      canvas.drawPath(
        Path()..addPolygon(pts, false),
        line
          ..color = seriesColor
          ..strokeWidth = 2.5,
      );
    }

    // Projection (dashed, joined to the last actual point).
    if (projection.isNotEmpty) {
      final proj = [
        if (pts.isNotEmpty) pts.last,
        for (final (i, v) in projection.indexed) g.point(actual.length + i, v),
      ];
      if (proj.length > 1) {
        _dashed(
          canvas,
          Path()..addPolygon(proj, false),
          line
            ..color = seriesColor.withValues(alpha: 0.6)
            ..strokeWidth = 2,
          5,
          4,
        );
      }
    }

    // Needed pace: last actual point → target at the last slot (dotted).
    if (showNeeded && target > 0 && pts.isNotEmpty) {
      _dashed(
        canvas,
        Path()
          ..moveTo(pts.last.dx, pts.last.dy)
          ..lineTo(g.x(g.slots - 1), g.y(target)),
        line
          ..color = neededColor
          ..strokeWidth = 1.5,
        2,
        3,
      );
    }

    // "Now" dot.
    if (pts.isNotEmpty) {
      canvas.drawCircle(
        pts.last,
        4,
        Paint()
          ..style = PaintingStyle.fill
          ..color = seriesColor,
      );
    }

    // Month labels, thinned so neighbours never touch.
    if (labels.isNotEmpty) {
      final step = math.max(
        1,
        (labels.length * 44 / math.max(1, g.plot.width)).ceil(),
      );
      for (var i = 0; i < labels.length; i += step) {
        _text(canvas, labels[i], Offset(g.x(i), g.plot.bottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_SavingPainter o) =>
      o.actual != actual ||
      o.projection != projection ||
      o.target != target ||
      o.showNeeded != showNeeded ||
      o.plan != plan ||
      o.labels != labels ||
      o.seriesColor != seriesColor ||
      o.targetColor != targetColor;
}
