import 'package:flutter/material.dart';

import 'package:pp_forge_core/ui.dart';

class SourceChipItem {
  const SourceChipItem(
    this.label, {
    this.icon,
    this.color,
    this.tone = PpForgeChipTone.neutral,
  });

  final String label;
  final IconData? icon;

  final Color? color;
  final PpForgeChipTone tone;
}

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

class SourceChips extends StatelessWidget {
  const SourceChips({
    required this.items,
    this.maxVisible = 4,
    this.overflowLabel,
    super.key,
  });

  final List<SourceChipItem> items;
  final int maxVisible;

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
