import 'package:flutter/material.dart';

import '../tokens/chip_size.dart';
import '../tokens/hero_metrics.dart';

/// A hero card's inside: the theme's inset ([HeroMetrics.padding]) all round,
/// [rows] stacked [HeroMetrics.gap] apart (null rows skipped; a [HeroRow]
/// sets its own gap).
class HeroContent extends StatelessWidget {
  const HeroContent({required this.rows, this.padding, this.rowGap, super.key});

  final List<Widget?> rows;

  /// Null = [HeroMetrics.padding].
  final EdgeInsetsGeometry? padding;

  /// Null = [HeroMetrics.gap].
  final double? rowGap;

  @override
  Widget build(BuildContext context) {
    final metrics = HeroMetrics.of(context);
    final gap = rowGap ?? metrics.gap;
    final shown = rows.whereType<Widget>().toList();
    return Padding(
      padding: padding ?? metrics.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, r) in shown.indexed) ...[
            if (i > 0)
              SizedBox(
                height:
                    (r is HeroSpacedRow
                        ? (r as HeroSpacedRow).gapBefore
                        : null) ??
                    (shown[i - 1] is HeroSpacedRow
                        ? (shown[i - 1] as HeroSpacedRow).gapAfter
                        : null) ??
                    gap,
              ),
            r,
          ],
        ],
      ),
    );
  }
}

/// A hero row that sets its own gap above / below (null = the card's).
abstract interface class HeroSpacedRow {
  double? get gapBefore;
  double? get gapAfter;
}

/// A row of a hero card with its own gap: [gapBefore] / [gapAfter] replace
/// the card's gap on that side (null = the card's). For a row that already
/// carries air inside it — a fixed-height input row — so the space you see
/// matches the card's inset instead of adding to it.
class HeroRow extends StatelessWidget implements HeroSpacedRow {
  const HeroRow({
    required this.child,
    this.gapBefore,
    this.gapAfter,
    super.key,
  });

  final Widget child;
  @override
  final double? gapBefore;
  @override
  final double? gapAfter;

  @override
  Widget build(BuildContext context) => child;
}

/// A hero's row of controls: [leading] from the left (wrapping), [trailing]
/// on the right, [HeroMetrics.itemGap] between them, at least the theme's
/// control height tall so it doesn't jump when a control comes or goes.
class HeroTopRow extends StatelessWidget {
  const HeroTopRow({
    this.leading = const [],
    this.trailing = const [],
    super.key,
  });

  final List<Widget> leading;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final gap = HeroMetrics.of(context).itemGap;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: ControlSizes.of(context).control),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: leading,
            ),
          ),
          for (final t in trailing) ...[SizedBox(width: gap), t],
        ],
      ),
    );
  }
}
