import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_registry.dart';
import '../../domain/tag.dart';

/// Pill-shaped tag chip — `[icon] name [×count]`.
///
/// Used in the tags list page and as the form live-preview.
/// Visual rule: tag's accent colour (resolved from `iconCode.iconColors`)
/// drives the border, icon tint, and chip background opacity.
class TagChip extends StatelessWidget {
  const TagChip({
    required this.tag,
    this.onTap,
    this.onLongPress,
    this.onIconTap,
    super.key,
  });

  final Tag tag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final palette = Theme.of(context).extension<AppColors>()!;
    final color = tag.iconCode?.accentColorFor(palette) ?? palette.primary;
    final scheme = Theme.of(context).colorScheme;
    final usageLabel = l.tagsUsageCount(tag.usageCount);
    final iconData = IconRegistry.get(tag.iconCode?.icon, fallback: Icons.label_outline);

    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onIconTap != null)
          InkResponse(
            onTap: onIconTap,
            radius: 18,
            child: Icon(iconData, size: 18, color: color),
          )
        else
          Icon(iconData, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            tag.name.isEmpty ? l.tagFormNameLabel : tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        if (usageLabel.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            usageLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );

    return Material(
      color: color.withValues(alpha: 0.12),
      shape: StadiumBorder(side: BorderSide(color: color, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: body,
        ),
      ),
    );
  }
}
