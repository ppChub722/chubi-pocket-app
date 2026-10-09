import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/skeletons.dart';

/// Cold-load skeleton for the categories list — a section-header line
/// followed by tree-indented rows, mirroring [CategoriesPage]'s layout so
/// the swap to real content doesn't jump. Co-located with the page.
class CategoriesListSkeleton extends StatelessWidget {
  const CategoriesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Indent pattern roughly matching a parent → child tree.
    const rows = <double>[
      0,
      AppSpacing.xxl,
      AppSpacing.xxl,
      0,
      AppSpacing.xxl,
      0,
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SkeletonLine(width: 110, height: 12),
        ),
        for (final indent in rows)
          SkeletonListTile(indent: indent, avatarSize: 36, lines: 1),
      ],
    );
  }
}
