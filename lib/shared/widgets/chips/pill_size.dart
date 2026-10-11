import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';

/// The three sizes of the one chip, [AppChip] (owner 2026-10-11) — everything
/// (icon, text, padding, gap, avatar, count badge) scales with the size:
///
/// - [mini] 20 — chips that ride on a dense list row next to text (a
///   transaction / pending row: wallet, source, tags; a scheduled card's
///   label). Display only, never the only tap target.
/// - [chip] 28 — display chips (status, type, label, tag) inside cards,
///   detail sections, member / debt rows and the compact hero bar.
/// - [control] 32 — anything the user operates (filter / pick / choice /
///   action chips, form chip rows, theme chips, removable filters) and every
///   chip in a hero's top row, so it lines up with the 32 date chip and ✏️
///   ([HeroSpacing.controlHeight]). The default.
enum PillSize {
  /// Dense list-row chips.
  mini(
    height: 20,
    padding: 6,
    gap: 3,
    icon: 11,
    dot: 5,
    leading: 14,
    badgeText: 9,
    badgePad: 3,
  ),

  /// Display chips in cards, rows and detail sections.
  chip(
    height: 28,
    padding: 10,
    gap: 4,
    icon: 14,
    dot: 7,
    leading: 18,
    badgeText: 10,
    badgePad: 4,
  ),

  /// Controls, and every chip in a hero's top row.
  control(
    height: 32,
    padding: AppSpacing.md,
    gap: AppSpacing.xs,
    icon: 16,
    dot: 8,
  );

  const PillSize({
    required this.height,
    required this.padding,
    required this.gap,
    required this.icon,
    required this.dot,
    this.leading = 22,
    this.badgeText = 11,
    this.badgePad = 5,
  });

  /// Minimum height (text scaling can grow it).
  final double height;

  /// Side padding.
  final double padding;

  /// Space between icon / dot and label.
  final double gap;
  final double icon;
  final double dot;

  /// The leading avatar / logo box.
  final double leading;

  /// [AppChip] count badge: its number size and side padding; its height is
  /// [icon] + 2.
  final double badgeText;
  final double badgePad;

  /// The label's text style — colour is the chip's own; every chip uses
  /// the same weight ([chipWeight]) so a selection never changes its width.
  TextStyle? textStyle(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return switch (this) {
      mini => t.labelSmall?.copyWith(fontSize: 10, height: 1.2),
      chip => t.labelMedium,
      control => t.labelLarge,
    };
  }

  /// The one label weight of a chip.
  static const FontWeight chipWeight = FontWeight.w600;
}
