import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../atoms/shown_tween_builder.dart';
import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';
import 'pointer_bubbles.dart';

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
    this.alert,
    this.alertColor,
    this.markerLabel,
    this.alertLabel,
    this.markerBubble,
    this.fillLabel,
    this.fillDot = false,
    this.endLabel,
    super.key,
  });

  /// A round dot on the end of the fill (in place of a [fillLabel] pill);
  /// pair it with [marker] = the fill + [markerBubble] for the amount.
  final bool fillDot;

  /// Words at the bar's right end, on its line (the whole: "฿20,000"); the
  /// bar is that much shorter.
  final String? endLabel;

  final double value;

  final double? expected;

  final String? label;

  final String? trailing;
  final Color? color;
  final Color? overColor;
  final double height;

  final double? marker;

  final List<double> ticks;

  /// A second line on the bar (a budget's warn point), in [alertColor].
  final double? alert;
  final Color? alertColor;

  /// Small words over the [marker] / [alert] lines ("today", "warn").
  final String? markerLabel;
  final String? alertLabel;

  /// Always shown over the [marker] in a bubble of the bar's color ("plan to
  /// date ฿1,300"). It stays inside the bar's width, its arrow on the line,
  /// and takes the place of the small labels.
  final String? markerBubble;

  /// A pill in the bar's color sitting on the end of the fill ("31%"),
  /// kept inside the bar's width.
  final String? fillLabel;

  static (double used, double total) segments(double value, double? expected) {
    final used = value.clamp(0, 1).toDouble();
    final total = (value + (expected ?? 0)).clamp(used, 1).toDouble();
    return (used, total);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    final over = value > 1;
    final barColor = over
        ? (overColor ?? hero?.danger ?? scheme.error)
        : (color ?? hero?.accent ?? scheme.primary);
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: hero?.muted ?? scheme.onSurfaceVariant,
    );
    final (used, total) = segments(value, expected);
    final alertC = alertColor ?? hero?.warning ?? scheme.tertiary;
    final bubble = marker != null && markerBubble != null;
    final labels = bubble
        ? PointerBubbles(
            key: const ValueKey('progressMarkerBubble'),
            bubbles: [
              PointerBubble(
                at: marker!.clamp(0, 1).toDouble(),
                text: markerBubble!,
                color: barColor,
              ),
            ],
          )
        : _tickLabels(context, alertC);
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: ShownTweenBuilder<Offset>(
        tween: Tween(begin: Offset.zero, end: Offset(used, total)),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: hero?.track ?? scheme.surfaceContainerHighest),
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
                      bubble
                          ? barColor
                          : (hero?.text ?? scheme.onSurface).withValues(
                              alpha: 0.55,
                            ),
                    ),
                  ),
                ),
              if (alert != null)
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('progressAlert'),
                    painter: _MarkerPainter(
                      alert!.clamp(0, 1).toDouble(),
                      alertC,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final withFill = fillLabel != null || fillDot
        ? _withFillLabel(context, bar, barColor, used)
        : bar;
    final end = endLabel;
    final line = end == null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [?labels, withFill],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [?labels, withFill],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // The size of a hero fact's value (the lines under it).
              Text(
                end,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hero?.text ?? scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        line,
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

  /// The "31%" pill in [color] that sits on the end of the fill, with its
  /// size.
  static (Widget, double, double) fillPill(
    BuildContext context,
    String label,
    Color color, {
    double minHeight = 0,
  }) {
    final onFill =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final small = Theme.of(context).textTheme.labelSmall;
    final style = small?.copyWith(
      fontSize: (small.fontSize ?? 11) - 2,
      fontWeight: FontWeight.w700,
      color: onFill,
      height: 1.2,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = tp.width + (AppSpacing.xs + AppSpacing.xxs) * 2;
    final h = math.max(minHeight, tp.height + AppSpacing.xxs * 2);
    final pill = Container(
      key: const ValueKey('progressFillLabel'),
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(h / 2),
      ),
      child: Text(label, maxLines: 1, style: style),
    );
    return (pill, w, h);
  }

  Widget _withFillLabel(
    BuildContext context,
    Widget bar,
    Color barColor,
    double used,
  ) {
    final dot = height * 2;
    final (pill, pillW, pillH) = fillLabel != null
        ? fillPill(context, fillLabel!, barColor, minHeight: height)
        : (
            Container(
              key: const ValueKey('progressFillDot'),
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: barColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
            dot,
            dot,
          );
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: pillH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: (pillH - height) / 2,
                child: bar,
              ),
              ShownTweenBuilder<double>(
                tween: Tween(begin: 0, end: used),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Positioned(
                  left: (v * w - pillW / 2).clamp(
                    0.0,
                    math.max(0.0, w - pillW),
                  ),
                  top: 0,
                  child: child!,
                ),
                child: pill,
              ),
            ],
          ),
        );
      },
    );
  }

  /// The words over the lines, each centred on its line (kept inside the
  /// bar's width). Two lines too close for both: only the alert's shows.
  Widget? _tickLabels(BuildContext context, Color alertC) {
    final muted =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final items = <(double, String, Color)>[
      if (marker != null && markerLabel != null)
        (marker!.clamp(0, 1).toDouble(), markerLabel!, muted),
      if (alert != null && alertLabel != null)
        (alert!.clamp(0, 1).toDouble(), alertLabel!, alertC),
    ];
    if (items.isEmpty) return null;
    if (items.length == 2 && (items[0].$1 - items[1].$1).abs() < 0.18) {
      items.removeAt(0);
    }
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final placed = [
            for (final (at, text, color) in items)
              (
                at,
                text,
                color,
                (TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: direction,
                  textScaler: scaler,
                  maxLines: 1,
                )..layout()),
              ),
          ];
          final h = placed.map((p) => p.$4.height).fold(0.0, math.max);
          return SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final (at, text, color, tp) in placed)
                  Positioned(
                    left: (at * w - tp.width / 2).clamp(
                      0.0,
                      math.max(0.0, w - tp.width),
                    ),
                    top: 0,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: style?.copyWith(color: color),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
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
