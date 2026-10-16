import 'package:flutter/material.dart';

import 'package:pp_forge/pp_forge.dart';

/// One thing that feeds a budget / goal: a category, a tag, a wallet — or a
/// "kind" of money (normal · event · recurring ahead · pending).
class SourceChipItem {
  const SourceChipItem(
    this.label, {
    this.icon,
    this.color,
    this.tone = PpForgeChipTone.neutral,
  });

  final String label;
  final IconData? icon;

  /// An entity's own colour (a category's tint); wins over [tone].
  final Color? color;
  final PpForgeChipTone tone;
}

/// A small soft pill naming a source (the mockup's `.src`): mini size, a
/// quiet tint. [color] (an entity's colour) wins over [tone].
class SourceChip extends StatelessWidget {
  const SourceChip(
    this.label, {
    this.icon,
    this.color,
    this.tone = PpForgeChipTone.neutral,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final PpForgeChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => PpForgeChip(
    label: label,
    icon: icon,
    color: color,
    tone: tone,
    selected: true,
    size: ChipSize.mini,
    maxWidth: 160,
    onTap: onTap,
  );
}

/// What feeds a budget as a wrapping row of [SourceChip]s, e.g. the
/// categories / tags / wallets it counts. At most [maxVisible] show; the rest
/// fold into one "+n" chip ([overflowLabel] builds its text, default "+n").
class SourceChips extends StatelessWidget {
  const SourceChips({
    required this.items,
    this.maxVisible = 4,
    this.overflowLabel,
    super.key,
  });

  final List<SourceChipItem> items;
  final int maxVisible;

  /// The folded chip's text from how many are hidden.
  final String Function(int hidden)? overflowLabel;

  @override
  Widget build(BuildContext context) {
    final shown = items.length > maxVisible
        ? items.take(maxVisible).toList()
        : items;
    final hidden = items.length - shown.length;
    return Wrap(
      spacing: PpForgeSpacing.xs,
      runSpacing: PpForgeSpacing.xs,
      children: [
        for (final i in shown)
          SourceChip(i.label, icon: i.icon, color: i.color, tone: i.tone),
        if (hidden > 0) SourceChip(overflowLabel?.call(hidden) ?? '+$hidden'),
      ],
    );
  }
}
