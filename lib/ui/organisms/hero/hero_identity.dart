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
    this.alignTop = true,
    super.key,
  });

  /// The icon and the buttons sit at the top of the row, not centred on the
  /// text — every detail page (owner 2026-10-23). False = centred.
  final bool alignTop;

  /// One icon size in view and edit (owner 2026-10-23): a view icon (40)
  /// scales up to the edit one (44, the EditableCircle).
  static const double iconSize = 44;

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
    final mark = icon;
    return Row(
      crossAxisAlignment: editing || alignTop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (mark != null)
          SizedBox.square(
            dimension: iconSize,
            child: FittedBox(fit: BoxFit.contain, child: mark),
          ),
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
