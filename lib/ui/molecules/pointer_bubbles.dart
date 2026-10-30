import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../tokens/app_spacing.dart';

@immutable
class PointerBubble {
  const PointerBubble({
    required this.at,
    required this.text,
    required this.color,
    this.strong = false,
  });

  /// Where the arrow points, 0..1 across the row.
  final double at;
  final String text;
  final Color color;

  /// Filled with [color] (the current point); others are tinted. A strong
  /// bubble wins when two would overlap: the other one is left out.
  final bool strong;
}

/// Small labels over points of a bar or a chain, each with an arrow at its
/// point, kept inside the row.
class PointerBubbles extends StatelessWidget {
  const PointerBubbles({required this.bubbles, super.key});

  final List<PointerBubble> bubbles;

  static const _arrow = 5.0;
  static const _padX = AppSpacing.sm;
  static const _padY = 1.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    // Measure with the style the Text really gets (the inherited one + the
    // label) and the app's locale, so Thai is measured in the font it is
    // drawn in; the bubble then sits centred on its point.
    final base = DefaultTextStyle.of(context).style.merge(
      Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    final locale = Localizations.maybeLocaleOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final placed =
            <({PointerBubble b, double left, double bw, double bh})>[];
        final ordered = [
          ...bubbles.where((b) => b.strong),
          ...bubbles.where((b) => !b.strong),
        ];
        for (final b in ordered) {
          final tp = TextPainter(
            text: TextSpan(text: b.text, style: base),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            locale: locale,
            maxLines: 1,
          )..layout();
          final bw = tp.width + 2 * _padX + 2;
          final bh = tp.height + 2 * _padY + 2;
          final x = b.at.clamp(0, 1) * w;
          final left = (x - bw / 2)
              .clamp(0.0, math.max(0.0, w - bw))
              .toDouble();
          final clash = placed.any(
            (p) => left < p.left + p.bw + _gap && p.left < left + bw + _gap,
          );
          if (!clash) placed.add((b: b, left: left, bw: bw, bh: bh));
        }
        if (placed.isEmpty) return const SizedBox.shrink();
        final height = placed.map((p) => p.bh).reduce(math.max);
        return SizedBox(
          height: height + _arrow + 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final p in placed) ..._bubble(p, w, height, surface, base),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _bubble(
    ({PointerBubble b, double left, double bw, double bh}) p,
    double w,
    double height,
    Color surface,
    TextStyle? base,
  ) {
    final b = p.b;
    final fill = b.strong
        ? b.color
        : Color.alphaBlend(b.color.withValues(alpha: 0.12), surface);
    final edge = b.strong
        ? b.color
        : Color.alphaBlend(b.color.withValues(alpha: 0.4), surface);
    final ink = b.strong ? AppChip.readableOn(b.color) : b.color;
    final x = b.at.clamp(0, 1) * w;
    final arrowX = x
        .clamp(p.left + _arrow + 1, p.left + p.bw - _arrow - 1)
        .toDouble();
    final top = height - p.bh;
    // One shape — box and arrow share a single outline, so no line cuts
    // across the arrow's root (owner 2026-10-23).
    return [
      Positioned(
        left: p.left,
        top: top,
        child: CustomPaint(
          painter: _BubblePainter(
            fill: fill,
            edge: edge,
            boxHeight: p.bh,
            tailX: arrowX - p.left,
          ),
          // Exactly the measured width, so the arrow math holds.
          child: SizedBox(
            width: p.bw,
            height: p.bh + _arrow,
            child: Padding(
              padding: const EdgeInsets.only(bottom: _arrow),
              child: Center(
                child: Text(
                  b.text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: base?.copyWith(color: ink),
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// A rounded box with its arrow under [tailX], drawn as one path (fill, then
/// a 1px outline round the whole thing).
class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.fill,
    required this.edge,
    required this.boxHeight,
    required this.tailX,
  });

  final Color fill;
  final Color edge;
  final double boxHeight;
  final double tailX;

  static const _r = AppSpacing.sm;
  static const _a = PointerBubbles._arrow;

  @override
  void paint(Canvas canvas, Size size) {
    // Half a pixel in, so the 1px outline sits fully inside the bounds.
    const i = 0.5;
    final w = size.width - i;
    final h = boxHeight - i;
    final r = math.min(_r, (h - i) / 2);
    final t = tailX.clamp(i + _a, w - _a).toDouble();
    // A tail near an edge (the first / last point) takes room from that
    // bottom corner, which rounds less, so the arrow still hits its point.
    final rl = math.max(0.0, math.min(r, t - _a - i));
    final rr = math.max(0.0, math.min(r, w - (t + _a)));
    final path = Path()
      ..moveTo(i + r, i)
      ..lineTo(w - r, i)
      ..arcToPoint(Offset(w, i + r), radius: Radius.circular(r))
      ..lineTo(w, h - rr)
      ..arcToPoint(Offset(w - rr, h), radius: Radius.circular(rr))
      ..lineTo(t + _a, h)
      ..lineTo(t, h + _a)
      ..lineTo(t - _a, h)
      ..lineTo(i + rl, h)
      ..arcToPoint(Offset(i, h - rl), radius: Radius.circular(rl))
      ..lineTo(i, i + r)
      ..arcToPoint(Offset(i + r, i), radius: Radius.circular(r))
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fill != fill ||
      old.edge != edge ||
      old.boxHeight != boxHeight ||
      old.tailX != tailX;
}
