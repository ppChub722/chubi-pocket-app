import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
import '../../tokens/hero_colors.dart';

/// A status chip, then the big amount in [color] ("รอรับ ฿1,232").
class StatusAmountLine extends StatelessWidget {
  const StatusAmountLine({
    required this.status,
    required this.amount,
    this.tone = AppChipTone.neutral,
    this.color,
    this.icon,
    this.chipSize = ChipSize.mini,
    super.key,
  });

  /// A debt's role chip is control-sized, level with the big amount.
  final ChipSize chipSize;

  final String status;

  /// Before the status word (a debt's ↙ / ↗).
  final IconData? icon;

  /// The amount (an amount text); it is styled big here.
  final Widget amount;
  final AppChipTone tone;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        AppChip(
          label: status,
          icon: icon,
          tone: tone,
          selected: true,
          size: chipSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: DefaultTextStyle.merge(
            style: text.headlineMedium?.copyWith(
              color: color ?? HeroColors.maybeOf(context)?.accent,
              fontWeight: FontWeight.w700,
            ),
            child: amount,
          ),
        ),
      ],
    );
  }
}
