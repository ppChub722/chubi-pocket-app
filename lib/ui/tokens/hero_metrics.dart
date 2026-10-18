import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_spacing.dart';

/// A hero card's spacing as a theme value: the inset, the gap between its
/// rows (header · content · footer alike), the gap between controls in a
/// row, the space after the card, and the folded / compact shapes.
class HeroMetrics extends ThemeExtension<HeroMetrics> {
  const HeroMetrics({
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.gap = AppSpacing.md,
    this.itemGap = AppSpacing.sm,
    this.after = AppSpacing.lg,
    this.foldedRadius = AppRadius.xl,
    this.compactHeight = 44,
  });

  final EdgeInsets padding;
  final double gap;
  final double itemGap;
  final double after;
  final double foldedRadius;
  final double compactHeight;

  static const HeroMetrics fallback = HeroMetrics();

  static HeroMetrics of(BuildContext context) =>
      Theme.of(context).extension<HeroMetrics>() ?? fallback;

  @override
  HeroMetrics copyWith({
    EdgeInsets? padding,
    double? gap,
    double? itemGap,
    double? after,
    double? foldedRadius,
    double? compactHeight,
  }) => HeroMetrics(
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    itemGap: itemGap ?? this.itemGap,
    after: after ?? this.after,
    foldedRadius: foldedRadius ?? this.foldedRadius,
    compactHeight: compactHeight ?? this.compactHeight,
  );

  @override
  HeroMetrics lerp(HeroMetrics? other, double t) {
    if (other == null) return this;
    return HeroMetrics(
      padding: EdgeInsets.lerp(padding, other.padding, t)!,
      gap: lerpDouble(gap, other.gap, t)!,
      itemGap: lerpDouble(itemGap, other.itemGap, t)!,
      after: lerpDouble(after, other.after, t)!,
      foldedRadius: lerpDouble(foldedRadius, other.foldedRadius, t)!,
      compactHeight: lerpDouble(compactHeight, other.compactHeight, t)!,
    );
  }
}
