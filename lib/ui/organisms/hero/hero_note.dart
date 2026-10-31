import 'package:flutter/material.dart';

import '../../atoms/app_icon.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';
import '../../tokens/icon_size.dart';
import '../../atoms/busy_scope.dart';

/// An icon with a count beside it in the hero's caption line (👛 3, 🔗 1);
/// [label] is what it means, for the tooltip and screen readers.
class CountMark extends StatelessWidget {
  const CountMark({
    required this.icon,
    required this.count,
    required this.label,
    super.key,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color =
        HeroColors.maybeOf(context)?.muted ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: AppIconSize.sm, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroCaption extends StatelessWidget {
  const HeroCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color:
          HeroColors.maybeOf(context)?.muted ??
          Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class HeroNote extends StatelessWidget {
  const HeroNote({
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
    this.onTap,
    super.key,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.bodySmall,
      child: child,
    );
    return Align(
      alignment: alignment,
      child: onTap == null
          ? body
          : BusyLock(
              child: InkWell(onTap: onTap, child: body),
            ),
    );
  }
}
