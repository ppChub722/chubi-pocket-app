import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/icon_maker/icon_display.dart';
import '../../../../shared/icon_maker/icon_type.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../domain/category.dart';

/// Reusable category-row card. Used as form live-preview and inside the
/// icon-maker sheet preview builder.
class CategoryPreviewCard extends StatelessWidget {
  const CategoryPreviewCard({
    required this.category,
    this.parentPath,
    this.onIconTap,
    super.key,
  });

  final Category category;
  final String? parentPath;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent =
        category.iconCode?.accentColorFor(palette) ?? palette.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            EditableCircle(
              size: 44,
              onTap: onIconTap,
              child: IconDisplay(
                type: IconType.category,
                size: 44,
                iconCode: category.iconCode,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.name.isEmpty
                        ? l.categoryFormNameLabel
                        : category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (parentPath != null && parentPath!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      parentPath!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (!category.includeInReport) ...[
                    const SizedBox(height: 2),
                    Text(
                      l.categoryHiddenFromReport,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
