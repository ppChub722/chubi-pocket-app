import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/skeletons.dart';

/// Cold-load skeleton for the contacts list — a stack of row placeholders
/// (avatar + name/detail lines). Co-located with the page.
class ContactsListSkeleton extends StatelessWidget {
  const ContactsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 8; i++)
          const SkeletonListTile(avatarSize: 40, lines: 2),
      ],
    );
  }
}
