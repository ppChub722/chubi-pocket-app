import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'dashed_rect_border.dart';

/// Shape of an [AddTile].
enum AddTileVariant {
  /// Full-width dashed card — end of card/grid collections, empty-state CTA.
  card,

  /// Compact dashed row — inside lists and forms ("+ เพิ่มการหาร").
  row,

  /// Dashed circle + caption — avatar strips ("+ เชิญ").
  circle,
}

/// The app's "add something here" affordance: brand-coloured dashed outline,
/// transparent fill, centred `+` and label. Visually distinct from real
/// items so the user reads it as "the way to add one".
class AddTile extends StatelessWidget {
  const AddTile({
    required this.label,
    required this.onTap,
    this.variant = AddTileVariant.card,
    this.icon = AppIcons.add,
    this.circleSize = 48,
    this.inList = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final AddTileVariant variant;
  final IconData icon;

  /// Diameter for [AddTileVariant.circle] — match the avatars beside it.
  final double circleSize;

  /// The tile that ends a full-width list ([ListPageBody] with no side
  /// padding): inset like the rows and spaced from the last one.
  final bool inList;

  @override
  Widget build(BuildContext context) {
    final tile = _tile(context);
    if (!inList) return tile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: tile,
    );
  }

  Widget _tile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = onTap == null ? scheme.outline : scheme.primary;
    final labelStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600);

    switch (variant) {
      case AddTileVariant.circle:
        return InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: circleSize + AppSpacing.lg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DashedRectBorder(
                  color: color,
                  borderRadius: Radius.circular(circleSize / 2),
                  child: SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: Icon(icon, color: color),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        );
      case AddTileVariant.card:
      case AddTileVariant.row:
        final isCard = variant == AddTileVariant.card;
        final radius = isCard ? AppRadius.lg : AppRadius.md;
        return DashedRectBorder(
          color: color,
          borderRadius: Radius.circular(radius),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
