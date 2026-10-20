import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';

/// "วันนี้ 20 ต.ค." and a line to the end: where today falls in a dated list.
class TodayLine extends StatelessWidget {
  const TodayLine({required this.label, this.color, super.key});

  final String label;

  /// Defaults to the card's accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent =
        color ??
        HeroColors.maybeOf(context)?.accent ??
        Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
