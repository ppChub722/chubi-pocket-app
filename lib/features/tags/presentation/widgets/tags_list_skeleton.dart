import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/skeletons.dart';

/// Cold-load skeleton for the tags manage list — a stack of row
/// placeholders (icon + name line). Co-located with the page.
class TagsListSkeleton extends StatelessWidget {
  const TagsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 8; i++)
          const SkeletonListTile(avatarSize: 40, lines: 1),
      ],
    );
  }
}
