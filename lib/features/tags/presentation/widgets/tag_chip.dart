import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/tag.dart';

/// Pill-shaped tag chip — `[icon] name [×count]`.
///
/// Used in two places:
/// - **Tags list page** — wrapped in a `Wrap`, sorted by usage count.
///   Tap = edit, long-press = delete confirm.
/// - **Tag form preview** — tap-on-icon opens the
///   `IconColorPickerSheet`. The chip re-renders as the user edits.
///
/// Visual rule: tag's [Tag.color] drives the border + icon + text;
/// chip background uses the same color tinted at low opacity so the
/// chip reads as "this color, just calmed down".
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

  /// When set, the leading icon becomes its own tap target — used by
  /// the form preview to open the picker without hijacking the chip's
  /// outer tap (which would normally open the edit form).
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = tag.color.color;
    final scheme = Theme.of(context).colorScheme;
    final usageLabel = l.tagsUsageCount(tag.usageCount);

    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onIconTap != null)
          InkResponse(
            onTap: onIconTap,
            radius: 18,
            child: Icon(tag.icon.icon, size: 18, color: color),
          )
        else
          Icon(tag.icon.icon, size: 18, color: color),
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
