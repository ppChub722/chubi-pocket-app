import 'package:flutter/material.dart';

import '../../molecules/hero_shell.dart';

/// The inputs have a fixed-height value row with air of its own, so this row
/// adds no gap above or below.
class HeroFields extends StatelessWidget implements HeroSpacedRow {
  const HeroFields({
    required this.end,
    this.start,
    this.endFraction = 0.48,
    this.onEndAreaTap,
    this.below = const [],
    this.gapBefore = 0,
    this.gapAfter = 0,
    super.key,
  });

  final Widget? start;
  final Widget end;
  final double endFraction;
  final VoidCallback? onEndAreaTap;
  final List<Widget> below;

  @override
  final double? gapBefore;
  @override
  final double? gapAfter;

  @override
  Widget build(BuildContext context) {
    final lead = start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final endWidth = lead == null
                ? box.maxWidth
                : box.maxWidth * endFraction;
            return Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lead == null)
                      Expanded(child: end)
                    else ...[
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.bottomStart,
                          child: lead,
                        ),
                      ),
                      SizedBox(width: endWidth, child: end),
                    ],
                  ],
                ),
                if (onEndAreaTap != null)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: 0,
                    width: endWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: onEndAreaTap,
                    ),
                  ),
              ],
            );
          },
        ),
        ...below,
      ],
    );
  }
}
