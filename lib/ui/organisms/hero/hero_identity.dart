import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import 'app_hero_card.dart';

/// In edit mode the inputs are taller than the icon, so the row aligns to the top.
class HeroIdentity extends StatelessWidget {
  const HeroIdentity({
    this.icon,
    this.name,
    this.fact,
    this.description,
    this.trailing,
    this.below,
    super.key,
  });

  final Widget? icon;
  final Widget? name;
  final Widget? fact;
  final Widget? description;
  final Widget? trailing;

  /// Under the icon and text, beside a tall [trailing] (a wallet's balance
  /// next to its month box); the row then aligns to the top.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final muted =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final text = Theme.of(context).textTheme;
    final editing = AppHeroScope.maybeOf(context)?.editing ?? false;
    final hasText = name != null || fact != null || description != null;
    final under = below;
    if (under != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                HeroIdentity(
                  icon: icon,
                  name: name,
                  fact: fact,
                  description: description,
                ),
                const SizedBox(height: AppSpacing.md),
                under,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: editing
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ?icon,
        if (icon != null && hasText) const SizedBox(width: AppSpacing.md),
        if (hasText)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name != null)
                  DefaultTextStyle.merge(style: text.titleMedium, child: name!),
                if (fact != null)
                  DefaultTextStyle.merge(
                    style: text.bodySmall?.copyWith(color: muted),
                    child: fact!,
                  ),
                if (description != null) ...[
                  if (name != null || fact != null) const SizedBox(height: 2),
                  description!,
                ],
              ],
            ),
          ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
