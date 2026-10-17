import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../atoms/skeleton_box.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.skeleton});

  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) return skeleton!;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [
        SkeletonBox(height: 24, width: 200),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 80),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 80),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 80),
      ],
    );
  }
}
