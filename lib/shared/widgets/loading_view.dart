import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import 'skeleton_box.dart';

/// Shown while async data loads.
///
/// Per design-sheet §8.5: lists pass per-row skeletons via [skeleton]; non-list
/// async screens fall back to a generic shimmer block. **No spinners on lists.**
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.skeleton});

  /// Optional custom skeleton — typically a [Column] of per-row skeleton
  /// widgets matching the eventual content shape.
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    if (skeleton != null) return skeleton!;

    // Generic fallback: stack of three shimmer blocks. Phase 1+ list screens
    // should pass an explicit skeleton instead.
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
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
