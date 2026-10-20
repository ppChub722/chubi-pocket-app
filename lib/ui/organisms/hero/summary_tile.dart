import 'package:flutter/material.dart';

import '../../atoms/app_card.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app/module_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/hero_colors.dart';

enum SummaryTileTone { neutral, green, amber, red, orange, planning }

@immutable
class SummaryTile {
  const SummaryTile({
    required this.label,
    required this.value,
    this.tone = SummaryTileTone.neutral,
    this.selected = false,
    this.onTap,
    this.caption,
    this.captionWidget,
  });

  final String label;
  final String value;
  final SummaryTileTone tone;
  final bool selected;
  final VoidCallback? onTap;

  final String? caption;

  final Widget? captionWidget;
}

/// A summary tile as a widget — a hero's footer tile (list pages: one
/// filter each, [SummaryTile.selected] rings it).
class SummaryTileView extends StatelessWidget {
  const SummaryTileView({required this.tile, super.key});

  final SummaryTile tile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    // In a hero a neutral tile takes the card's color, the rest its status set.
    final hero = HeroColors.maybeOf(context);
    final muted = hero?.muted ?? scheme.onSurfaceVariant;
    final color = switch (tile.tone) {
      SummaryTileTone.neutral => hero?.accent ?? scheme.onSurfaceVariant,
      SummaryTileTone.green => hero?.success ?? palette.income,
      SummaryTileTone.amber => hero?.warning ?? palette.warning,
      SummaryTileTone.red => hero?.danger ?? palette.expense,
      SummaryTileTone.orange => Colors.deepOrange,
      SummaryTileTone.planning => ModuleColors.of(context).planning,
    };
    final valueColor = tile.tone == SummaryTileTone.neutral
        ? (hero?.text ?? scheme.onSurface)
        : color;
    return Semantics(
      button: tile.onTap != null,
      selected: tile.selected,
      // Selected = the card's own edge turns primary; no ring around it, so
      // the tile keeps the same edges and gaps whether chosen or not.
      child: AppCard(
        key: ValueKey('summaryTile:${tile.label}'),
        style: AppCardStyle.tinted,
        color: color,
        selected: tile.selected,
        radius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        onTap: tile.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tile.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            // A long amount shrinks to fit a narrow tile instead of "…".
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                tile.value,
                maxLines: 1,
                style: textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (tile.caption != null)
              Text(
                tile.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(color: muted),
              ),
          ],
        ),
      ),
    );
  }
}
