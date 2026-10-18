import 'package:flutter/material.dart';

import '../../atoms/app_card.dart';
import '../../molecules/selectable_frame.dart';
import '../../tokens/app/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

enum SummaryTileTone { neutral, green, amber, red, orange }

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
    final color = switch (tile.tone) {
      SummaryTileTone.neutral => scheme.onSurfaceVariant,
      SummaryTileTone.green => palette.income,
      SummaryTileTone.amber => palette.warning,
      SummaryTileTone.red => palette.expense,
      SummaryTileTone.orange => Colors.deepOrange,
    };
    final valueColor = tile.tone == SummaryTileTone.neutral
        ? scheme.onSurface
        : color;
    return Semantics(
      button: tile.onTap != null,
      selected: tile.selected,
      child: SelectableFrame(
        selected: tile.selected,
        radius: AppRadius.md,
        gap: 2,
        child: AppCard(
          key: ValueKey('summaryTile:${tile.label}'),
          style: AppCardStyle.tinted,
          color: color,
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
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tile.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tile.caption != null)
                Text(
                  tile.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
