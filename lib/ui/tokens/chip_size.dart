import 'package:flutter/material.dart';

abstract final class ChipHeight {
  static const double mini = 20;
  static const double chip = 28;
  static const double control = 36;
}

enum ChipSize {
  mini(
    height: ChipHeight.mini,
    padding: 6,
    gap: 3,
    icon: 11,
    dot: 5,
    leading: 14,
    badgeText: 9,
    badgePad: 3,
  ),

  chip(
    height: ChipHeight.chip,
    padding: 10,
    gap: 4,
    icon: 14,
    dot: 7,
    leading: 18,
    badgeText: 10,
    badgePad: 4,
  ),

  control(
    height: ChipHeight.control,
    padding: 12,
    gap: 5,
    icon: 16,
    dot: 8,
    leading: 24,
    badgeText: 11,
    badgePad: 5,
  );

  const ChipSize({
    required this.height,
    required this.padding,
    required this.gap,
    required this.icon,
    required this.dot,
    this.leading = 22,
    this.badgeText = 11,
    this.badgePad = 5,
  });

  final double height;

  final double padding;

  final double gap;
  final double icon;
  final double dot;

  final double leading;

  final double badgeText;
  final double badgePad;

  /// The label's text style — colour is the chip's own; every chip uses the
  /// same weight ([chipWeight]) so a selection never changes its width.
  TextStyle? textStyle(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return switch (this) {
      mini => t.labelSmall?.copyWith(fontSize: 10, height: 1.2),
      chip => t.labelMedium,
      control => t.labelLarge,
    };
  }

  static const FontWeight chipWeight = FontWeight.w600;
}
