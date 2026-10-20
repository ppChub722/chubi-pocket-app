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
    final base = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final placed = <({PointerBubble b, double left, double bw, double bh})>[];
        final ordered = [
          ...bubbles.where((b) => b.strong),
          ...bubbles.where((b) => !b.strong),
        ];
        for (final b in ordered) {
          final tp = TextPainter(
            text: TextSpan(text: b.text, style: base),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final bw = tp.width + 2 * _padX + 2;
          final bh = tp.height + 2 * _padY + 2;
          final x = b.at.clamp(0, 1) * w;
          final left = (x - bw / 2).clamp(0.0, math.max(0.0, w - bw)).toDouble();
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
        .clamp(p.left + _arrow + 2, p.left + p.bw - _arrow - 2)
        .toDouble();
    final top = height - p.bh;
    return [
      Positioned(
        left: arrowX - _arrow,
        top: top + p.bh - 1,
        child: CustomPaint(
          size: const Size(_arrow * 2, _arrow),
          painter: _ArrowPainter(fill, edge),
        ),
      ),
      Positioned(
        left: p.left,
        top: top,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: edge),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _padX,
              vertical: _padY,
            ),
            child: Text(b.text, maxLines: 1, style: base?.copyWith(color: ink)),
          ),
        ),
      ),
    ];
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.fill, this.edge);

  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.fill != fill || old.edge != edge;
}
