import 'package:flutter/material.dart';

import '../../atoms/app_chip.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';
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
    this.actions = const [],
    this.below,
    super.key,
  });

  final Widget? icon;
  final Widget? name;
  final Widget? fact;
  final Widget? description;
  final Widget? trailing;

  /// Round buttons at the end (🪪 / 🔍), spaced like [HeroSummaryHead]'s;
  /// used when there is no [trailing].
  final List<Widget> actions;

  Widget? get _end =>
      trailing ??
      (actions.isEmpty
          ? null
          : ChipSizeScope(
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
            ));

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
    final trailing = _end;
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
            trailing,
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
          trailing,
        ],
      ],
    );
  }
}
