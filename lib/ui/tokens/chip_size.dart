import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The one source of control heights for chips, round buttons and pills.
class ControlSizes extends ThemeExtension<ControlSizes> {
  const ControlSizes({this.mini = 20, this.chip = 28, this.control = 36});

  final double mini;
  final double chip;
  final double control;

  static const ControlSizes fallback = ControlSizes();

  static ControlSizes of(BuildContext context) =>
      Theme.of(context).extension<ControlSizes>() ?? fallback;

  double heightOf(ChipSize size) => switch (size) {
    ChipSize.mini => mini,
    ChipSize.chip => chip,
    ChipSize.control => control,
  };

  @override
  ControlSizes copyWith({double? mini, double? chip, double? control}) =>
      ControlSizes(
        mini: mini ?? this.mini,
        chip: chip ?? this.chip,
        control: control ?? this.control,
      );

  @override
  ControlSizes lerp(ControlSizes? other, double t) {
    if (other == null) return this;
    return ControlSizes(
      mini: lerpDouble(mini, other.mini, t)!,
      chip: lerpDouble(chip, other.chip, t)!,
      control: lerpDouble(control, other.control, t)!,
    );
  }
}

enum ChipSize {
  mini(
    padding: 6,
    gap: 3,
    icon: 11,
    dot: 5,
    leading: 14,
    badgeText: 9,
    badgePad: 3,
  ),

  chip(
    padding: 10,
    gap: 4,
    icon: 14,
    dot: 7,
    leading: 18,
    badgeText: 10,
    badgePad: 4,
  ),

  control(
    padding: 12,
    gap: 5,
    icon: 16,
    dot: 8,
    leading: 24,
    badgeText: 11,
    badgePad: 5,
  );

  const ChipSize({
    required this.padding,
    required this.gap,
    required this.icon,
    required this.dot,
    this.leading = 22,
    this.badgeText = 11,
    this.badgePad = 5,
  });

  double heightOf(BuildContext context) =>
      ControlSizes.of(context).heightOf(this);

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
