import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/tone.dart';
import '../../atoms/busy_scope.dart';

/// One occurrence as a cell of [OccurrenceTileGrid] (ปรับแต่งล่วงหน้า):
/// [label] (its month, or weekday for a weekly rule) over the big [day], then
/// [amount]. A [tag] pill top-right in [tone], and [was] struck under the
/// amount (the usual amount, or the day it moved from). [highlight] edges it
/// in the primary colour (ถัดไป); an info [tone] washes it (แก้ / เลื่อน);
/// [struck] crosses out the day and amount (ข้าม).
class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({
    required this.label,
    required this.day,
    required this.amount,
    this.amountColor,
    this.tag,
    this.tone = Tone.neutral,
    this.was,
    this.highlight = false,
    this.struck = false,
    this.onTap,
    super.key,
  });

  final String label;
  final int day;
  final String amount;
  final Color? amountColor;
  final String? tag;
  final Tone tone;
  final String? was;
  final bool highlight;
  final bool struck;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final edge = highlight ? Tone.primary.color(context) : tone.color(context);
    final washed = highlight || tone == Tone.info;
    final faint = scheme.onSurfaceVariant.withValues(alpha: 0.6);
    final radius = BorderRadius.circular(AppRadius.lg);
    final struckStyle = struck
        ? TextStyle(color: faint, decoration: TextDecoration.lineThrough)
        : const TextStyle();
    return Material(
      color: struck
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : washed
          ? edge.withValues(alpha: 0.08)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: highlight
              ? edge
              : washed
              ? edge.withValues(alpha: 0.35)
              : scheme.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: BusyLock(
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm + 2,
                AppSpacing.sm,
                AppSpacing.xs + 2,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (tag != null) _Tag(tag!, color: struck ? faint : edge),
                    ],
                  ),
                  Text(
                    '$day',
                    style: text.titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: !struck && tone == Tone.info && was != null
                              ? edge
                              : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                        .merge(struckStyle),
                  ),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: amountColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                        .merge(struckStyle),
                  ),
                  if (was != null)
                    Text(
                      was!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: on,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.6,
        ),
      ),
    );
  }
}

/// [OccurrenceTile]s three to a row, each row as tall as its tallest.
class OccurrenceTileGrid extends StatelessWidget {
  const OccurrenceTileGrid({
    required this.children,
    this.columns = 3,
    super.key,
  });

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = [
        for (var k = 0; k < columns; k++) ...[
          if (k > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: i + k < children.length
                ? children[i + k]
                : const SizedBox.shrink(),
          ),
        ],
      ];
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.sm));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
