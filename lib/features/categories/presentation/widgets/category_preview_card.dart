import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/editable_circle.dart';
import '../../domain/category.dart';

/// Reusable category-row card. Used in two places:
/// - **Form live preview** — re-renders as the user edits name / picks
///   icon / picks color, with a tappable icon (pencil overlay) that opens
///   the icon-color picker sheet.
/// - **Picker sheet preview** — same widget, no tap on the icon (passive
///   preview inside the sheet).
///
/// Layout matches the categories list row (`[icon] Name • parent path`)
/// so what users see in the form / picker is exactly what they'll see in
/// the list.
class CategoryPreviewCard extends StatelessWidget {
  const CategoryPreviewCard({
    required this.category,
    this.parentPath,
    this.onIconTap,
    super.key,
  });

  final Category category;

  /// Breadcrumb-style path of ancestors, e.g. `"Food & Drinks"` or `"Food
  /// & Drinks › Groceries"`. Null = top-level (no breadcrumb shown).
  final String? parentPath;

  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: category.color.color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            EditableCircle(
              size: 44,
              onTap: onIconTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon.icon,
                  color: Colors.white,
                  size: 22,
                ),
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
