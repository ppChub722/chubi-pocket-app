import 'package:flutter/material.dart';

/// The three sizes of the one chip, [AppChip] (owner 2026-10-11) — everything
/// (icon, text, padding, gap, avatar, count badge) scales with the size:
///
/// - [mini] 20 — chips that ride on a dense list row next to text (a
///   transaction / pending row: wallet, source, tags; a scheduled card's
///   label). Display only, never the only tap target.
/// - [chip] 28 — display chips (status, type, label, tag) inside cards,
///   detail sections, member / debt rows and the compact hero bar.
/// - [control] 40 — anything the user operates (filter / pick / choice /
///   action chips, form chip rows, theme chips, removable filters) and every
///   chip in a hero's top row, so it lines up with the date chip, ✏️, the
///   search capsule and the top-bar pills: ONE control height, 40
///   ([HeroSpacing.controlHeight]). The default.
enum ChipSize {
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
    height: 40,
    padding: 14,
    gap: 6,
    icon: 18,
    dot: 9,
    leading: 28,
    badgeText: 12,
    badgePad: 6,
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
