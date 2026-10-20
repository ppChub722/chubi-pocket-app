import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import '../tokens/icon_size.dart';
import 'chip_row.dart';

/// A muted icon, then chips: what a record carries, shown quietly under its
/// hero (a transaction's tags; a budget's categories, wallets, tags).
class IconChipStrip extends StatelessWidget {
  const IconChipStrip({
    required this.icon,
    required this.chips,
    this.size = ChipSize.chip,
    this.maxLines,
    this.onLongPress,
    super.key,
  });

  final IconData icon;
  final List<Widget> chips;

  /// The chips' size: the icon centres on their first line.
  final ChipSize size;

  /// Null wraps every chip; a number folds the rest into a "+N" that opens.
  final int? maxLines;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final lines = maxLines;
    final strip = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: size.heightOf(context),
          child: Center(
            child: AppIcon(
              icon,
              size: AppIconSize.md,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: lines == null
              ? Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: chips,
                )
              : LimitedChipWrap(
                  chips: chips,
                  maxLines: lines,
                  expandable: true,
                  size: size,
                ),
        ),
      ],
    );
    if (onLongPress == null) return strip;
    return GestureDetector(onLongPress: onLongPress, child: strip);
  }
}
