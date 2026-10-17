import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../atoms/skeleton_box.dart';
import '../../molecules/hero_shell.dart';
import '../../molecules/hero_style.dart';
import '../../tokens/chip_size.dart';

/// The EntryCard (quick create / pending draft) while its first load runs,
/// built from the SAME tokens the real card lays out with, so nothing jumps
/// when the form appears:
///
///   [type chips]                [📅 date]      ← HeroTopRow, control height
///   description label · amount label           ← AppInputSize.labelRow
///   description value · amount value           ← AppInputSize.hero.valueRow
///   [wallet chip row]                          ← [rows] chip rows, control
///   [category chip row]                           height, itemGap apart
///
/// [rows] = the chip rows inside the card: 2 (wallet + category), 2 for a
/// transfer (from + to wallet). Pass [editing] false for the view look (no
/// field labels).
class EntryCardSkeleton extends StatelessWidget {
  const EntryCardSkeleton({this.rows = 2, this.editing = true, super.key});

  final int rows;
  final bool editing;

  /// Under a sized card field's value row: its bottom inset + the underline
  /// (kept equal to AppInput's by entry_card_skeleton_geometry_test).
  static const double _fieldBottom = 8;

  @override
  Widget build(BuildContext context) {
    final control = ChipSize.control.height;
    final label = editing
        ? AppInputSize.scaled(context, AppInputSize.labelRow)
        : 0.0;
    final value = AppInputSize.scaled(context, AppInputSize.hero.valueRow);
    // The hero's top row keeps its own 40 min height (✏️ is a 40 control);
    // the chip rows under the fields are chip-control tall.
    const top = HeroSpacing.controlHeight;
    Widget pill({double? width, double height = 0}) => SkeletonBox(
      width: width,
      height: height == 0 ? control : height,
      borderRadius: (height == 0 ? control : height) / 2,
    );
    return HeroSurface(
      style: const HeroStyle.plain(),
      child: HeroContent(
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
                  if (i > 0) const SizedBox(height: HeroSpacing.itemGap),
                  pill(),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
