import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';

/// The head of a list hero's plan section: the plan's title, with a stepper
/// (a month, a round) before it when the plan can be stepped; no divider.
/// Without [stepper] it is the plain title, not tappable.
class HeroStepperHead extends StatelessWidget {
  const HeroStepperHead({required this.title, this.stepper, super.key});

  final Widget? stepper;
  final String title;

  @override
  Widget build(BuildContext context) {
    final muted =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final stepper = this.stepper;
    return Row(
      children: [
        if (stepper != null) ...[stepper, const SizedBox(width: AppSpacing.sm)],
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
