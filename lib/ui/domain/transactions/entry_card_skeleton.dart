import 'package:flutter/material.dart';

import '../../atoms/skeleton_box.dart';
import '../../atoms/skeletons.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

/// The EntryCard (quick create / pending draft) while it loads: the same hero
/// surface and rhythm — a type-chip row, the amount, the title, then
/// [rows] picker rows (wallet / category / date).
class EntryCardSkeleton extends StatelessWidget {
  const EntryCardSkeleton({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return HeroSurface(
      style: const HeroStyle.plain(),
      child: Padding(
        padding: const EdgeInsets.all(HeroSpacing.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: 200,
              height: ChipSize.control.height,
              borderRadius: 20,
            ),
            const SizedBox(height: HeroSpacing.rowGap),
            const SkeletonText(style: _displaySmall, width: 160),
            const SizedBox(height: HeroSpacing.rowGap),
            const SkeletonText(style: _bodyLarge, width: 220),
            for (var i = 0; i < rows; i++) ...[
              const SizedBox(height: AppSpacing.md),
              SkeletonBox(height: ChipSize.control.height, borderRadius: 20),
            ],
          ],
        ),
      ),
    );
  }
}

TextStyle? _displaySmall(TextTheme t) => t.headlineMedium;
TextStyle? _bodyLarge(TextTheme t) => t.bodyLarge;
