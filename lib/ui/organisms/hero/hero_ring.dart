import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../atoms/shown_tween_builder.dart';
import '../../molecules/progress_row.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import 'hero_facts.dart';

/// A ring beside its facts. The facts get half the row, at least
/// [factsMinWidth] (room for a seven-digit amount); the ring takes what is
/// left, up to [maxRing].
class HeroRingRow extends StatelessWidget {
  const HeroRingRow({
    required this.ring,
    required this.facts,
    this.factsMinWidth = 176,
    this.maxRing = 160,
    super.key,
  });

  /// Builds the [HeroRing] at the size the row gives it.
  final Widget Function(double size) ring;
  final List<HeroFact> facts;
  final double factsMinWidth;
  final double maxRing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = AppSpacing.lg;
      final factsWidth = math.max(factsMinWidth, box.maxWidth / 2);
      final size = (box.maxWidth - gap - factsWidth).clamp(96.0, maxRing);
      return Row(
        children: [
          ring(size),
          const SizedBox(width: gap),
          Expanded(child: HeroFactList(facts: facts)),
        ],
      );
    },
  );
}

/// A hero's ring: how much of a limit is used, what is expected on top
/// (lighter) and an alert tick, with the number inside. Over the base ring a
/// shade starts at a round head at the top and is gone by half way, so the
/// start reads even at 0. No pace tick (owner 2026-10-26: a light line on the
/// ring reads as a glitch); the pace lives in the facts.
/// Colors come from the card; [color] paints over the fill (a warning or over
/// state).
class HeroRing extends StatelessWidget {
  const HeroRing({
    required this.value,
    required this.amount,
    this.label,
    this.target,
    this.expected,
    this.alert,
    this.color,
    this.size = 124,
    this.stroke = 12,
    super.key,
  });

  /// Used / limit; above 1 fills the whole ring.
  final double value;

  /// The number in the middle (an amount text); it is styled big here.
  final Widget amount;
  final String? label;
  final String? target;
  final double? expected;

  /// The warn point, as a share of the ring (in the warning colour).
  final double? alert;
  final Color? color;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final accent = hero?.accent ?? scheme.primary;
    final fill = color ?? accent;
    final track = hero?.track ?? scheme.surfaceContainerHighest;
    final muted = hero?.muted ?? scheme.onSurfaceVariant;
    final small = text.labelSmall?.copyWith(color: muted);
    final (used, total) = ProgressRow.segments(value, expected);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShownTweenBuilder<Offset>(
            tween: Tween(begin: Offset.zero, end: Offset(used, total)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => CustomPaint(
              key: const ValueKey('heroRing'),
              size: Size.square(size),
              painter: _RingPainter(
                used: v.dx,
                total: v.dy,
                alert: alert?.clamp(0.0, 1.0),
                stroke: stroke,
                fill: fill,
                trackStart: hero?.line ?? Color.lerp(track, accent, 0.25)!,
                trackEnd: hero?.soft ?? scheme.surfaceContainerHigh,
                alertColor: hero?.warning ?? scheme.tertiary,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(stroke + AppSpacing.sm),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) Text(label!, style: small),
                  DefaultTextStyle.merge(
                    style: text.titleLarge?.copyWith(
                      color: fill,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    child: amount,
                  ),
                  if (target != null) Text(target!, style: small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.used,
    required this.total,
    required this.alert,
    required this.stroke,
    required this.fill,
    required this.trackStart,
    required this.trackEnd,
    required this.alertColor,
  });

  final double used;
  final double total;
  final double? alert;
  final double stroke;
  final Color fill;
  final Color trackStart;
  final Color trackEnd;
  final Color alertColor;

  static const _tickOut = 4.0;
  static const _top = -math.pi / 2;
  static const _minExpected = 0.02;
  static const _startGap = 0.01;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - stroke) / 2 - _tickOut;
    final arc = Rect.fromCircle(center: center, radius: r);
    Paint ring(Color c, {StrokeCap cap = StrokeCap.butt}) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = cap
      ..color = c;

    // The base ring, then a shade from the start that is gone by half way.
    canvas.drawCircle(center, r, ring(trackEnd));
    canvas.drawCircle(
      center,
      r,
      ring(trackStart)
        ..shader = SweepGradient(
          colors: [trackStart, trackStart.withValues(alpha: 0)],
          stops: const [0, 0.5],
          transform: const GradientRotation(_top),
        ).createShader(arc),
    );
    // A round dark head over the faded tail marks where the ring starts.
    canvas.drawCircle(
      center + Offset(0, -r),
      stroke / 2,
      Paint()..color = trackStart,
    );
    // Under 2% the expected part is too small to read as a share (the facts
    // list still names it); above it, round ends keep it a short arc.
    if (total - used >= _minExpected) {
      canvas.drawArc(
        arc,
        _top + used * 2 * math.pi,
        (total - used) * 2 * math.pi,
        false,
        ring(fill.withValues(alpha: 0.4), cap: StrokeCap.round),
      );
    }
    if (used > 0) {
      canvas.drawArc(
        arc,
        _top,
        used * 2 * math.pi,
        false,
        ring(fill, cap: StrokeCap.round),
      );
    }
    // The warn point, never on the start point (it would read as a start
    // marker).
    final at = alert;
    if (at != null && at > _startGap && at < 1 - _startGap) {
      final a = _top + at * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (r - stroke / 2 - _tickOut + 1),
        center + dir * (r + stroke / 2 + _tickOut - 1),
        Paint()
          ..color = alertColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.used != used ||
      old.total != total ||
      old.alert != alert ||
      old.stroke != stroke ||
      old.fill != fill ||
      old.trackStart != trackStart ||
      old.trackEnd != trackEnd ||
      old.alertColor != alertColor;
}
