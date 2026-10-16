import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../atoms/icon_tile.dart';
import '../tokens/app_spacing.dart';

/// A grid of [TileCard]s that sits inside a scrolling page: fixed card height,
/// the column count follows the width (2 on phones, 3–4 on wide screens) so
/// the cards never balloon into empty slabs. The More page's groups.
class CardGrid extends StatelessWidget {
  const CardGrid({
    required this.children,
    this.maxCrossAxisExtent = 240,
    this.mainAxisExtent = 124,
    super.key,
  });

  final List<Widget> children;

  /// The widest a card may get (decides the column count).
  final double maxCrossAxisExtent;

  /// Every card's height.
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) => GridView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      mainAxisExtent: mainAxisExtent,
      mainAxisSpacing: PpForgeSpacing.sm,
      crossAxisSpacing: PpForgeSpacing.sm,
    ),
    children: children,
  );
}

/// One tile of a [CardGrid]: a card washed in the group's [color] with a faded
/// corner glyph, a solid rounded [IconTile], the title and a subtitle (the
/// More page's entries).
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

  /// The group colour.
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return PpForgeCard(
      style: PpForgeCardStyle.tinted,
      color: color,
      glyph: icon,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(PpForgeSpacing.md),
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
