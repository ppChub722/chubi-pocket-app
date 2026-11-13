import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/category.dart';
import '../../../../ui/ui.dart';

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
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final accent = category.iconCode.tintFor(palette);
    return PpForgeCard(
      style: PpForgeCardStyle.accent,
      color: accent,
      child: Padding(
        padding: const EdgeInsets.all(PpForgeSpacing.md),
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
            const SizedBox(width: PpForgeSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PpForgeText(
                    category.name.isEmpty ? l.commonName : category.name,
                    role: PpForgeTextRole.title,
                    maxLines: 1,
                  ),
                  if (parentPath != null && parentPath!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    PpForgeText(
                      parentPath!,
                      role: PpForgeTextRole.caption,
                      maxLines: 1,
                    ),
                  ],
                  if (!category.includeInReport) ...[
                    const SizedBox(height: 2),
                    PpForgeText(
                      l.categoryHiddenFromReport,
                      role: PpForgeTextRole.caption,
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
