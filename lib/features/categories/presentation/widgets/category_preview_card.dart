import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/category.dart';
import '../../../../ui/ui.dart';

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
    final palette = Theme.of(context).extension<AppColors>()!;
    final accent = category.iconCode.tintFor(palette);
    return AppCard(
      style: AppCardStyle.accent,
      color: accent,
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
                  AppText(
                    category.name.isEmpty ? l.commonName : category.name,
                    role: AppTextRole.title,
                    maxLines: 1,
                  ),
                  if (parentPath != null && parentPath!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppText(
                      parentPath!,
                      role: AppTextRole.caption,
                      maxLines: 1,
                    ),
                  ],
                  if (!category.includeInReport) ...[
                    const SizedBox(height: 2),
                    AppText(
                      l.categoryHiddenFromReport,
                      role: AppTextRole.caption,
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
