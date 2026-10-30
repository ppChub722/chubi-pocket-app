import 'package:flutter/material.dart';

import '../../atoms/dashed_rect_border.dart';
import '../../tokens/app/app_colors.dart';
import '../icons/color_token.dart';

/// A person's profile colours 1…[count] as dots (0.4.2 1b, under the avatar
/// on the profile hero): a set slot = its colour, an unset one (past the
/// end of [colors], or '') = a dashed ring. Colours are drawn as picked
/// (theme token or `#rrggbb`), no contrast shift: they show the pick.
class ProfileColorDots extends StatelessWidget {
  const ProfileColorDots({
    required this.colors,
    this.count = 3,
    this.size = 12,
    this.gap = 5,
    this.semanticLabel,
    super.key,
  });

  final List<String> colors;
  final int count;
  final double size;
  final double gap;
  final String? semanticLabel;

  /// Slot [i] of [colors] ('' when unset).
  static String slotOf(List<String> colors, int i) =>
      i < colors.length ? colors[i] : '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>();
    Widget dot(String spec) {
      if (spec.isEmpty) {
        return DashedRectBorder(
          color: scheme.outline,
          strokeWidth: 1.2,
          dashLength: 2.5,
          gapLength: 2,
          borderRadius: Radius.circular(size / 2),
          child: SizedBox.square(dimension: size),
        );
      }
      final color = palette == null
          ? scheme.primary
          : resolveColor(spec, palette);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(width: gap),
            dot(slotOf(colors, i)),
          ],
        ],
      ),
    );
  }
}
