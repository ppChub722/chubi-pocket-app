import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

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

  final double? expected;

  final String? label;

  final String? trailing;
  final Color? color;
  final Color? overColor;
  final double height;

  final double? marker;

  final List<double> ticks;

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
