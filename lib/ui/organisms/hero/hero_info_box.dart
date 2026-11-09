import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../../tokens/icon_size.dart';

/// A box set into a hero ([HeroColors.inset], darker than the card in dark
/// mode) with the card's line border: a month's list, the next occurrence.
class HeroInsetBox extends StatelessWidget {
  const HeroInsetBox({
    required this.child,
    this.padding = const EdgeInsets.all(PpForgeSpacing.md),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hero = HeroColors.maybeOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hero?.insetOrSoft ?? scheme.surfaceContainer,
        border: Border.all(color: hero?.line ?? scheme.outlineVariant),
        borderRadius: BorderRadius.circular(PpForgeRadius.lg),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A small boxed fact beside a hero's actions (a budget's round: "Monthly on
/// the 1st", "12 days left | 20/31"). It keeps to [maxWidth] and ends its
/// lines in "…", so the name beside it keeps its room.
class HeroInfoBox extends StatelessWidget {
  const HeroInfoBox({
    required this.title,
    this.icon,
    this.subtitle,
    this.maxWidth = 168,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hero?.soft ?? scheme.surfaceContainer,
          border: Border.all(color: hero?.line ?? scheme.outlineVariant),
          borderRadius: BorderRadius.circular(PpForgeRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PpForgeSpacing.sm + PpForgeSpacing.xxs,
            vertical: PpForgeSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    PpForgeIcon(
                      icon!,
                      size: PpForgeIconSize.sm,
                      color: hero?.accent ?? scheme.primary,
                    ),
                    const SizedBox(width: PpForgeSpacing.xxs),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: hero?.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: hero?.muted ?? scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
