import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import 'app_hero_card.dart';

/// In edit mode the inputs are taller than the icon, so the row aligns to the top.
class HeroIdentity extends StatelessWidget {
  const HeroIdentity({
    this.icon,
    this.name,
    this.fact,
    this.description,
    this.trailing,
    super.key,
  });

  final Widget? icon;
  final Widget? name;
  final Widget? fact;
  final Widget? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final editing = AppHeroScope.maybeOf(context)?.editing ?? false;
    final hasText = name != null || fact != null || description != null;
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
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
