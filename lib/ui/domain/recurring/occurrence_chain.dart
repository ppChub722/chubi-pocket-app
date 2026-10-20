import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../molecules/pointer_bubbles.dart';
import '../../tokens/hero_colors.dart';

/// One occurrence's mark on an [OccurrenceChain].
enum ChainDot {
  /// Paid, with or without a transaction: the card's own color.
  paid,

  /// Due and waiting (to confirm, or for an amount).
  wait,
  skipped,

  /// The next one.
  current,
  future,
}

/// A recurring item's occurrences on one line. How it draws depends on how
/// many fit the width: a number in every dot, numbers only on the first /
/// current / last, plain dots with bubbles over those three, or (too many
/// for dots) a bar with the same three bubbles. An [open] chain (no end)
/// never numbers its dots, has no last bubble and fades out at the end.
class OccurrenceChain extends StatelessWidget {
  const OccurrenceChain({
    required this.dots,
    this.firstLabel,
    this.currentLabel,
    this.lastLabel,
    this.open = false,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final List<ChainDot> dots;

  /// The bubble / number text of the first, current and last dot. Null =
  /// its position (1, 5, 12).
  final String? firstLabel;
  final String? currentLabel;
  final String? lastLabel;

  final bool open;

  /// Null = the card's accent.
  final Color? color;
  final String? semanticLabel;

  static const double _numbered = 17;
  static const double _small = 10;
  static const double _plain = 8;
  static const double _curGrow = 4;
  static const double _minLine = 2;
  static const double _tail = 24;

  @override
  Widget build(BuildContext context) {
    if (dots.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final palette = _Palette(
      accent: color ?? hero?.accent ?? scheme.primary,
      warning: hero?.warning ?? scheme.tertiary,
      muted: (hero?.muted ?? scheme.onSurfaceVariant).withValues(alpha: 0.5),
      line: hero?.line ?? scheme.outlineVariant,
      track: hero?.track ?? scheme.surfaceContainerHighest,
      surface: scheme.surface,
    );
    final n = dots.length;
    final cur = dots.indexOf(ChainDot.current);
    String label(int i) => i == 0 && firstLabel != null
        ? firstLabel!
        : i == cur && currentLabel != null
        ? currentLabel!
        : i == n - 1 && lastLabel != null
        ? lastLabel!
        : '${i + 1}';
    bool key(int i) => i == 0 || i == cur || (!open && i == n - 1);
    return Semantics(
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final tail = open ? _tail : 0.0;
          double need(double Function(int) size) {
            var s = tail + (n - 1) * _minLine;
            for (var i = 0; i < n; i++) {
              s += size(i) + (i == cur ? _curGrow : 0);
            }
            return s;
          }

          final _Tier tier;
          if (!open && need((_) => _numbered) <= w) {
            tier = _Tier.allNumbers;
          } else if (!open &&
              n > 3 &&
              need((i) => key(i) ? _numbered : _small) <= w) {
            tier = _Tier.keyNumbers;
          } else if (need((_) => _plain) <= w) {
            tier = _Tier.dots;
          } else {
            tier = _Tier.bar;
          }

          final bubbles = <PointerBubble>[];
          void bubble(int i, double x, {bool strong = false}) => bubbles.add(
            PointerBubble(
              at: w == 0 ? 0 : x / w,
              text: label(i),
              color: strong ? palette.accent : palette.accent,
              strong: strong,
            ),
          );

          if (tier == _Tier.bar) {
            const r = 5.0;
            final span = math.max(1.0, w - 2 * r - tail);
            double xOf(int i) => r + (n == 1 ? 0 : i / (n - 1)) * span;
            bubble(0, xOf(0));
            if (cur >= 0) bubble(cur, xOf(cur), strong: true);
            if (!open) bubble(n - 1, xOf(n - 1));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                PointerBubbles(bubbles: bubbles),
                CustomPaint(
                  size: const Size.fromHeight(18),
                  painter: _BarPainter(
                    palette: palette,
                    current: cur < 0 ? 1 : (n == 1 ? 0 : cur / (n - 1)),
                    hasCurrent: cur >= 0,
                    open: open,
                    tail: tail,
                  ),
                ),
              ],
            );
          }

          double sizeOf(int i) =>
              switch (tier) {
                _Tier.allNumbers => _numbered,
                _Tier.keyNumbers => key(i) ? _numbered : _small,
                _ => _plain,
              } +
              (i == cur ? _curGrow : 0);
          var dotsW = 0.0;
          for (var i = 0; i < n; i++) {
            dotsW += sizeOf(i);
          }
          final lineW = n == 1 ? 0.0 : (w - tail - dotsW) / (n - 1);
          final centers = <double>[];
          var x = 0.0;
          for (var i = 0; i < n; i++) {
            centers.add(x + sizeOf(i) / 2);
            x += sizeOf(i) + lineW;
          }
          final numbered = <int, String>{
            for (var i = 0; i < n; i++)
              if (tier == _Tier.allNumbers ||
                  (tier == _Tier.keyNumbers && key(i)))
                i: label(i),
          };
          if (tier == _Tier.dots) {
            bubble(0, centers.first);
            if (cur >= 0) bubble(cur, centers[cur], strong: true);
            if (!open) bubble(n - 1, centers.last);
          }
          final height =
              (tier == _Tier.dots ? _plain : _numbered) + _curGrow + 8;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (bubbles.isNotEmpty) PointerBubbles(bubbles: bubbles),
              CustomPaint(
                size: Size.fromHeight(height),
                painter: _DotsPainter(
                  palette: palette,
                  dots: dots,
                  centers: centers,
                  sizes: [for (var i = 0; i < n; i++) sizeOf(i)],
                  numbers: numbered,
                  open: open,
                  textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    height: 1,
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _Tier { allNumbers, keyNumbers, dots, bar }

class _Palette {
  const _Palette({
    required this.accent,
    required this.warning,
    required this.muted,
    required this.line,
    required this.track,
    required this.surface,
  });

  final Color accent;
  final Color warning;
  final Color muted;
  final Color line;
  final Color track;
  final Color surface;

  @override
  bool operator ==(Object other) =>
      other is _Palette &&
      other.accent == accent &&
      other.warning == warning &&
      other.muted == muted &&
      other.line == line &&
      other.track == track &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(accent, warning, muted, line, track, surface);
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter({
    required this.palette,
    required this.dots,
    required this.centers,
    required this.sizes,
    required this.numbers,
    required this.open,
    required this.textStyle,
    required this.textScaler,
    required this.textDirection,
  });

  final _Palette palette;
  final List<ChainDot> dots;
  final List<double> centers;
  final List<double> sizes;
  final Map<int, String> numbers;
  final bool open;
  final TextStyle? textStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final line = Paint()
      ..color = palette.line
      ..strokeWidth = 2;
    for (var i = 0; i + 1 < centers.length; i++) {
      canvas.drawLine(
        Offset(centers[i] + sizes[i] / 2, cy),
        Offset(centers[i + 1] - sizes[i + 1] / 2, cy),
        line,
      );
    }
    if (open) {
      final from = centers.last + sizes.last / 2;
      canvas.drawLine(
        Offset(from, cy),
        Offset(size.width, cy),
        Paint()
          ..strokeWidth = 2
          ..shader = LinearGradient(
            colors: [palette.line, palette.line.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(from, cy - 1, size.width - from, 2)),
      );
    }
    for (var i = 0; i < dots.length; i++) {
      final c = Offset(centers[i], cy);
      final r = sizes[i] / 2;
      final (fill, edge, ink) = switch (dots[i]) {
        ChainDot.paid => (palette.accent, palette.accent, null),
        ChainDot.wait => (palette.warning, palette.warning, null),
        ChainDot.skipped => (palette.muted, palette.muted, null),
        ChainDot.current => (
          Color.alphaBlend(
            palette.accent.withValues(alpha: 0.12),
            palette.surface,
          ),
          palette.accent,
          palette.accent,
        ),
        ChainDot.future => (palette.surface, palette.line, palette.muted),
      };
      if (dots[i] == ChainDot.current) {
        canvas.drawCircle(
          c,
          r + 3,
          Paint()..color = palette.accent.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(c, r, Paint()..color = fill);
      canvas.drawCircle(
        c,
        r - 0.75,
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = dots[i] == ChainDot.current ? 2 : 1.5,
      );
      final text = numbers[i];
      if (text != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: textStyle?.copyWith(color: ink ?? AppChip.readableOn(fill)),
          ),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.palette != palette ||
      old.dots != dots ||
      old.centers != centers ||
      old.sizes != sizes ||
      old.numbers != numbers ||
      old.open != open;
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.palette,
    required this.current,
    required this.hasCurrent,
    required this.open,
    required this.tail,
  });

  final _Palette palette;

  /// 0..1 along the bar.
  final double current;
  final bool hasCurrent;
  final bool open;
  final double tail;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 5.0;
    final cy = size.height / 2;
    final end = size.width - r - tail;
    final span = math.max(1.0, end - r);
    final track = RRect.fromLTRBR(
      0,
      cy - 3,
      size.width - tail,
      cy + 3,
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = palette.track);
    final x = r + current * span;
    canvas.drawRRect(
      RRect.fromLTRBR(0, cy - 3, x, cy + 3, const Radius.circular(3)),
      Paint()..color = palette.accent,
    );
    if (open) {
      canvas.drawLine(
        Offset(size.width - tail, cy),
        Offset(size.width, cy),
        Paint()
          ..strokeWidth = 6
          ..shader = LinearGradient(
            colors: [palette.track, palette.track.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(size.width - tail, cy - 3, tail, 6)),
      );
    }
    void mark(double at, {required bool filled, double radius = r}) {
      final c = Offset(at, cy);
      canvas.drawCircle(
        c,
        radius,
        Paint()..color = filled ? palette.accent : palette.surface,
      );
      canvas.drawCircle(
        c,
        radius - 1,
        Paint()
          ..color = palette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    mark(r, filled: true);
    if (!open) mark(end, filled: false);
    if (hasCurrent) {
      canvas.drawCircle(
        Offset(x, cy),
        r + 5,
        Paint()..color = palette.accent.withValues(alpha: 0.22),
      );
      mark(x, filled: false, radius: r + 2);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.palette != palette ||
      old.current != current ||
      old.hasCurrent != hasCurrent ||
      old.open != open ||
      old.tail != tail;
}
