import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../atoms/icon_tile.dart';
import '../tokens/app_spacing.dart';

class CardGrid extends StatelessWidget {
  const CardGrid({
    required this.children,
    this.maxCrossAxisExtent = 240,
    this.mainAxisExtent = 124,
    super.key,
  });

  final List<Widget> children;

  final double maxCrossAxisExtent;

  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) => GridView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      mainAxisExtent: mainAxisExtent,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
    ),
    children: children,
  );
}

class TileCard extends StatelessWidget {
  const TileCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      style: AppCardStyle.tinted,
      color: color,
      glyph: icon,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              icon: icon,
              color: color,
              size: 40,
              shape: IconTileShape.rounded,
              style: IconTileStyle.solid,
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
