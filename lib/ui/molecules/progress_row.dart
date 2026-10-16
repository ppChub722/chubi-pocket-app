import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Progress bar + caption — budgets, saving goals, debt repayment, credit
/// utilisation, project plan vs actual.
///
/// [value] is a ratio (0–1); above 1 the bar fills and turns [overColor]
/// (defaults to the error colour) to flag over-budget / over-limit.
///
/// [expected] (budgets, owner 2026-10-13): a further ratio drawn AFTER the
/// used part as a lighter striped segment in the same colour ("what the pace
/// says is still coming"). Both are unclamped inputs; the bar clamps the
/// TOTAL at 100 % (the segment is cut where the track ends), and the caption
/// % is the caller's string, so it can say "122%".
class ProgressRow extends StatelessWidget {
  const ProgressRow({
    required this.value,
    this.expected,
    this.label,
    this.trailing,
    this.color,
    this.overColor,
    this.height = 8,
    this.marker,
    this.ticks = const [],
    super.key,
  });

  final double value;

  /// The extra, not-yet-spent ratio drawn after [value] (null / 0 = none).
  final double? expected;

  /// Left caption under the bar ("คืนแล้ว ฿300 จาก ฿500").
  final String? label;

  /// Right caption under the bar ("60%", "เหลือ ฿200").
  final String? trailing;
  final Color? color;
  final Color? overColor;
  final double height;

  /// A thin tick across the bar at this ratio (0..1) — where spending "should"
  /// be today (a budget's pace, owner 2026-10-16). null = none.
  final double? marker;

  /// Thin white ticks at these ratios (0..1): a goal's 25 / 50 / 75 % (owner
  /// 2026-10-17). Empty = none.
  final List<double> ticks;

  /// The bar's two fractions of the track, both clamped to 0..1: where the
  /// used part ends, and where used + expected ends (the total, clamped).
  static (double used, double total) segments(double value, double? expected) {
    final used = value.clamp(0, 1).toDouble();
    final total = (value + (expected ?? 0)).clamp(used, 1).toDouble();
    return (used, total);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = value > 1;
    final barColor = over
        ? (overColor ?? scheme.error)
        : (color ?? scheme.primary);
    final captionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final (used, total) = segments(value, expected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(begin: Offset.zero, end: Offset(used, total)),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: scheme.surfaceContainerHighest),
                  if (v.dy > v.dx)
                    FractionallySizedBox(
                      key: const ValueKey('progressExpected'),
                      alignment: Alignment.centerLeft,
                      widthFactor: v.dy,
                      child: CustomPaint(painter: _StripePainter(barColor)),
                    ),
                  FractionallySizedBox(
                    key: const ValueKey('progressUsed'),
                    alignment: Alignment.centerLeft,
                    widthFactor: v.dx,
                    child: ColoredBox(color: barColor),
                  ),
                  if (ticks.isNotEmpty)
                    Positioned.fill(
                      child: CustomPaint(
                        key: const ValueKey('progressTicks'),
                        painter: _TicksPainter(
                          ticks,
                          Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  if (marker != null)
                    Positioned.fill(
                      child: CustomPaint(
                        key: const ValueKey('progressMarker'),
                        painter: _MarkerPainter(
                          marker!.clamp(0, 1).toDouble(),
                          scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (label != null || trailing != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: captionStyle?.copyWith(
                    color: over ? barColor : null,
                    fontWeight: over ? FontWeight.w600 : null,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A lighter fill with diagonal stripes — the "expected" segment.
class _StripePainter extends CustomPainter {
  const _StripePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.4),
    );
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width + size.height; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}

/// The pace tick: a 2px line across the full bar height at [at] of the track.
class _MarkerPainter extends CustomPainter {
  const _MarkerPainter(this.at, this.color);

  final double at;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (size.width * at).clamp(1.0, size.width - 1);
    canvas.drawRect(
      Rect.fromLTWH(x - 1, 0, 2, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.at != at || old.color != color;
}

/// Thin vertical ticks at [at] ratios of the track.
class _TicksPainter extends CustomPainter {
  const _TicksPainter(this.at, this.color);

  final List<double> at;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final r in at) {
      final x = size.width * r.clamp(0, 1);
      canvas.drawRect(Rect.fromLTWH(x - 1, 1, 2, size.height - 2), paint);
    }
  }

  @override
  bool shouldRepaint(_TicksPainter old) => old.at != at || old.color != color;
}
