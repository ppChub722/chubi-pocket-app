import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tokens/hero_colors.dart';

@immutable
class AmountPoint {
  const AmountPoint(this.label, this.amount, {this.amountText});

  /// The x label under the point (a month).
  final String label;
  final double amount;

  /// The label over the point; null = [amount] as a whole number.
  final String? amountText;
}

/// Amounts paid per period as a line (a bill whose amount changes): each
/// point with its amount, a dashed average line, and the next period as a
/// hollow "?" in warning on a dashed segment at the average.
class AmountLineChart extends StatelessWidget {
  const AmountLineChart({
    required this.points,
    this.average,
    this.averageLabel,
    this.nextLabel,
    this.color,
    this.height = 112,
    this.semanticLabel,
    super.key,
  });

  final List<AmountPoint> points;
  final double? average;

  /// The text at the end of the average line ("เฉลี่ย 1,240").
  final String? averageLabel;

  /// The next period's x label; null = no "?" point.
  final String? nextLabel;

  /// Null = the card's accent.
  final Color? color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: semanticLabel,
      child: CustomPaint(
        size: Size.fromHeight(height),
        painter: _LinePainter(
          points: points,
          average: average,
          averageLabel: averageLabel,
          nextLabel: nextLabel,
          line: color ?? hero?.accent ?? scheme.primary,
          warning: hero?.warning ?? scheme.tertiary,
          muted: hero?.muted ?? scheme.onSurfaceVariant,
          ink: hero?.text ?? scheme.onSurface,
          surface: scheme.surface,
          small: text.labelSmall,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.average,
    required this.averageLabel,
    required this.nextLabel,
    required this.line,
    required this.warning,
    required this.muted,
    required this.ink,
    required this.surface,
    required this.small,
    required this.textScaler,
    required this.textDirection,
  });

  final List<AmountPoint> points;
  final double? average;
  final String? averageLabel;
  final String? nextLabel;
  final Color line;
  final Color warning;
  final Color muted;
  final Color ink;
  final Color surface;
  final TextStyle? small;
  final TextScaler textScaler;
  final TextDirection textDirection;

  static const _padX = 18.0;
  static const _top = 22.0;
  static const _bottom = 20.0;

  TextPainter _text(String s, Color c, {bool bold = false}) => TextPainter(
    text: TextSpan(
      text: s,
      style: small?.copyWith(
        color: c,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final next = nextLabel != null;
    final n = points.length + (next ? 1 : 0);
    final values = [for (final p in points) p.amount, ?average];
    final lo = values.reduce(math.min) * 0.9;
    final hi = values.reduce(math.max) * 1.05;
    final range = hi - lo == 0 ? 1.0 : hi - lo;
    double x(int i) => n == 1
        ? size.width / 2
        : _padX + i * (size.width - 2 * _padX) / (n - 1);
    double y(double v) =>
        _top + (1 - (v - lo) / range) * (size.height - _top - _bottom);

    final avg = average;
    if (avg != null) {
      final ay = y(avg);
      _dashed(
        canvas,
        Offset(_padX, ay),
        Offset(size.width - _padX, ay),
        Paint()
          ..color = muted.withValues(alpha: 0.6)
          ..strokeWidth = 1,
      );
      if (averageLabel != null) {
        final tp = _text(averageLabel!, muted);
        tp.paint(
          canvas,
          Offset(size.width - _padX - tp.width, ay - tp.height - 2),
        );
      }
    }

    final pts = [
      for (var i = 0; i < points.length; i++) Offset(x(i), y(points[i].amount)),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height - _bottom)
      ..lineTo(pts.first.dx, size.height - _bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = line.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (next) {
      final nx = Offset(x(n - 1), y(avg ?? points.last.amount));
      _dashed(
        canvas,
        pts.last,
        nx,
        Paint()
          ..color = warning
          ..strokeWidth = 2,
      );
      canvas.drawCircle(nx, 6, Paint()..color = surface);
      canvas.drawCircle(
        nx,
        6,
        Paint()
          ..color = warning
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      final q = _text('?', warning, bold: true);
      q.paint(canvas, nx - Offset(q.width / 2, q.height + 8));
      final xl = _text(nextLabel!, line, bold: true);
      xl.paint(canvas, Offset(nx.dx - xl.width / 2, size.height - xl.height));
    }

    for (var i = 0; i < points.length; i++) {
      final p = pts[i];
      canvas.drawCircle(p, 4, Paint()..color = line);
      final a = _text(
        points[i].amountText ?? points[i].amount.round().toString(),
        ink,
        bold: true,
      );
      a.paint(canvas, Offset(p.dx - a.width / 2, p.dy - a.height - 6));
      final l = _text(points[i].label, muted);
      l.paint(canvas, Offset(p.dx - l.width / 2, size.height - l.height));
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final len = d.distance;
    if (len == 0) return;
    final u = d / len;
    for (var t = 0.0; t < len; t += 8) {
      canvas.drawLine(a + u * t, a + u * math.min(t + 4, len), paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.average != average ||
      old.averageLabel != averageLabel ||
      old.nextLabel != nextLabel ||
      old.line != line ||
      old.warning != warning ||
      old.muted != muted ||
      old.ink != ink;
}
