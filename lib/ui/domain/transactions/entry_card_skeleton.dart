import '../../tokens/hero_metrics.dart';
import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../atoms/skeleton_box.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../organisms/hero/hero_fields.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/chip_size.dart';

class EntryCardSkeleton extends StatelessWidget {
  const EntryCardSkeleton({this.rows = 2, this.editing = true, super.key});

  final int rows;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final control = ChipSize.control.heightOf(context);
    final hero = HeroMetrics.of(context);
    final label = editing
        ? AppInputSize.scaled(context, AppInputSize.labelRow)
        : 0.0;
    // The real inputs: label, their top inset, then the value row.
    final field =
        label +
        AppSpacing.xs +
        AppInputSize.scaled(context, AppInputSize.hero.valueRow);
    Widget pill({double? width}) =>
        SkeletonBox(width: width, height: control, borderRadius: control / 2);
    return HeroSurface(
      style: const HeroStyle.plain(),
      child: HeroContent(
        padding: hero.padding,
        rowGap: hero.gap,
        rows: [
          Row(children: [pill(width: 168), const Spacer(), pill(width: 96)]),
          HeroFields(
            start: SizedBox(
              height: field,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: 12, end: 48),
                    child: SkeletonBox(height: 18),
                  ),
                ],
              ),
            ),
            end: SizedBox(
              height: field,
              child: const Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonBox(width: 104, height: 30),
                ),
              ),
            ),
          ),
          if (rows > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                children: [
                  for (var i = 0; i < rows; i++) ...[
                    if (i > 0) SizedBox(height: hero.itemGap),
                    pill(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
