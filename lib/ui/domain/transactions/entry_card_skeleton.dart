import '../../tokens/hero_metrics.dart';
import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../atoms/skeleton_box.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../tokens/chip_size.dart';

class EntryCardSkeleton extends StatelessWidget {
  const EntryCardSkeleton({this.rows = 2, this.editing = true, super.key});

  final int rows;
  final bool editing;

  static const double _fieldBottom = 8;

  @override
  Widget build(BuildContext context) {
    final control = ChipSize.control.heightOf(context);
    final hero = HeroMetrics.of(context);
    final label = editing
        ? AppInputSize.scaled(context, AppInputSize.labelRow)
        : 0.0;
    final value = AppInputSize.scaled(context, AppInputSize.hero.valueRow);
    final top = control;
    Widget pill({double? width, double height = 0}) => SkeletonBox(
      width: width,
      height: height == 0 ? control : height,
      borderRadius: (height == 0 ? control : height) / 2,
    );
    return HeroSurface(
      style: const HeroStyle.plain(),
      child: HeroContent(
        padding: hero.padding,
        rowGap: hero.gap,
        rows: [
          Row(
            children: [
              pill(width: 168, height: top),
              const Spacer(),
              pill(width: 96, height: top),
            ],
          ),
          SizedBox(
            height: label + value + _fieldBottom,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12, right: 48),
                    child: SkeletonBox(height: 18),
                  ),
                ),
                const SizedBox(width: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: SkeletonBox(width: 104, height: 30),
                ),
              ],
            ),
          ),
          if (rows > 0)
            Column(
              children: [
                for (var i = 0; i < rows; i++) ...[
                  if (i > 0) SizedBox(height: hero.itemGap),
                  pill(),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
