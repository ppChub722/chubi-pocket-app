import 'package:flutter/material.dart';

import '../atoms/app_card.dart';
import '../atoms/app_chip.dart';
import '../atoms/icon_tile.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/tone.dart';
import 'status_chip.dart';

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

/// A small status chip in a [TileCard]'s top-right corner (over budget, due
/// soon…). The tone carries the meaning.
class TileStatus {
  const TileStatus(this.label, {this.tone = Tone.neutral});

  final String label;
  final Tone tone;
}

class TileCard extends StatelessWidget {
  const TileCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.statuses = const [],
    super.key,
  });

  static const double _iconSize = 40;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// At most two are shown, stacked in the top-right corner.
  final List<TileStatus> statuses;

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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: icon,
                  color: color,
                  size: _iconSize,
                  shape: IconTileShape.rounded,
                  style: IconTileStyle.solid,
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (statuses.isNotEmpty)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              left: AppSpacing.md + _iconSize + AppSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: AppSpacing.xs,
                children: [
                  for (final s in statuses.take(2))
                    StatusChip.tone(
                      label: s.label,
                      tone: AppChipTone.fromTone(s.tone),
                      size: ChipSize.mini,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
