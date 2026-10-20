import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../atoms/icon_tile.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/hero_colors.dart';
import 'hero_number.dart';

/// A list page's module icon at the top-left of its hero, in the card color.
class HeroModuleTile extends StatelessWidget {
  const HeroModuleTile(this.icon, {super.key});

  final IconData icon;

  static const double size = 40;

  @override
  Widget build(BuildContext context) => IconTile(
    icon: icon,
    color:
        HeroColors.maybeOf(context)?.accent ??
        Theme.of(context).colorScheme.primary,
    size: size,
    shape: IconTileShape.rounded,
    style: IconTileStyle.solid,
  );
}

/// The top row of a list hero led by one big number: the module tile, the
/// label over the amount, and the actions (🔍) at the end.
class HeroSummaryHead extends StatelessWidget {
  const HeroSummaryHead({
    required this.icon,
    required this.label,
    required this.amount,
    this.amountColor,
    this.actions = const [],
    super.key,
  });

  final IconData icon;
  final String label;
  final Widget amount;

  /// Null = the card's accent.
  final Color? amountColor;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HeroModuleTile(icon),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: HeroNumber(label: label, value: amount, color: amountColor),
      ),
      if (actions.isNotEmpty) ...[
        const SizedBox(width: AppSpacing.sm),
        ChipSizeScope(
          size: ChipSize.control,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                a,
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
