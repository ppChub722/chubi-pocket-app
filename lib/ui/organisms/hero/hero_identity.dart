import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
import 'app_hero_card.dart';

/// Who / what the hero is about: [icon] beside [name] (+ a short [fact],
/// people pages) and [description]. In edit / create mode the page passes the
/// editable versions (an `EditableCircle`, the name and description inputs)
/// and the row aligns them to the top.
class HeroIdentity extends StatelessWidget {
  const HeroIdentity({
    this.icon,
    this.name,
    this.fact,
    this.description,
    super.key,
  });

  final Widget? icon;
  final Widget? name;
  final Widget? fact;
  final Widget? description;

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
      ],
    );
  }
}
