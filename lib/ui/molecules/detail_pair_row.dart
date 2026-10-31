import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'detail_rows.dart';
import '../atoms/busy_scope.dart';

/// One column of a [DetailPairRow]: a label over its value.
@immutable
class DetailPairCell {
  const DetailPairCell({
    required this.label,
    required this.value,
    this.onTap,
    this.chevron = false,
  });

  final String label;
  final Widget value;

  /// The whole column is the tap target.
  final VoidCallback? onTap;
  final bool chevron;
}

/// Two settings side by side in one section row, each a label over its value,
/// a line between: [first] as wide as it needs (a check that switches a
/// mode), [second] the rest (what that mode asks for), so a long value or a
/// wrap of chips gets the room.
class DetailPairRow extends StatelessWidget {
  const DetailPairRow({
    required this.first,
    required this.second,
    this.onLongPress,
    super.key,
  });

  final DetailPairCell first;
  final DetailPairCell second;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(DetailPairCell c, {required bool grow}) {
      final value = DefaultTextStyle.merge(
        style: theme.textTheme.bodyLarge,
        child: c.value,
      );
      final body = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.label, style: detailLabelStyle(context)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (grow) Expanded(child: value) else value,
                if (c.chevron) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.chevronRight,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
      if (c.onTap == null) return body;
      return BusyLock(
        child: InkWell(onTap: c.onTap, child: body),
      );
    }

    return BusyLock(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cell(first, grow: false),
                VerticalDivider(
                  width: AppSpacing.md * 2 + 1,
                  thickness: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(child: cell(second, grow: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
