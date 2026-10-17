import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

class SourceChipItem {
  const SourceChipItem(
    this.label, {
    this.icon,
    this.color,
    this.tone = AppChipTone.neutral,
  });

  final String label;
  final IconData? icon;

  final Color? color;
  final AppChipTone tone;
}

class SourceChip extends StatelessWidget {
  const SourceChip(
    this.label, {
    this.icon,
    this.color,
    this.tone = AppChipTone.neutral,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final AppChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppChip(
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
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final i in shown)
          SourceChip(i.label, icon: i.icon, color: i.color, tone: i.tone),
        if (hidden > 0) SourceChip(overflowLabel?.call(hidden) ?? '+$hidden'),
      ],
    );
  }
}
