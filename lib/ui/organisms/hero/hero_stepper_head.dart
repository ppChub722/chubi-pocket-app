import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';

/// The head of a list hero's plan section: a stepper (a month, a round) with
/// the plan's title beside it, no divider.
class HeroStepperHead extends StatelessWidget {
  const HeroStepperHead({
    required this.stepper,
    required this.title,
    super.key,
  });

  final Widget stepper;
  final String title;

  @override
  Widget build(BuildContext context) {
    final muted =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        stepper,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
