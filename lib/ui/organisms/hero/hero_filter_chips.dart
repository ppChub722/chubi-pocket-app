import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

@immutable
class HeroFilter {
  const HeroFilter({
    required this.label,
    required this.count,
    this.tone,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final int count;

  /// A status color shown as a dot (ปกติ / ใกล้เต็ม / เกินงบ); null = none.
  final AppChipTone? tone;

  /// What the filter keeps (a wallet, a bank, a card); takes the dot's place.
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
}

/// A list hero's filters: one chip each with its count (ทั้งหมด 3, ● ปกติ 1).
/// It takes the place of a row of summary tiles.
class HeroFilterChips extends StatelessWidget {
  const HeroFilterChips({required this.filters, super.key});

  final List<HeroFilter> filters;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final f in filters)
        AppChip(
          key: ValueKey('heroFilter:${f.label}'),
          label: f.label,
          icon: f.icon,
          dot: f.icon == null && f.tone != null,
          tone: f.tone,
          selected: f.selected,
          trailing: AppChipTrailing.count,
          count: f.count,
          size: ChipSize.chip,
          onTap: f.onTap,
        ),
    ],
  );
}
