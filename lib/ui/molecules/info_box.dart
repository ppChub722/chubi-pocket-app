import 'package:flutter/material.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'detail_rows.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({required this.rows, this.first = false, super.key});

  final List<InfoRow> rows;
  final bool first;

  @override
  Widget build(BuildContext context) =>
      SectionCard(first: first, children: rows);
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.valueChip,
    this.valueChips,
    this.onTap,
    this.onLongPress,
    this.showChevron = false,
    super.key,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final Widget? valueChip;
  final List<Widget>? valueChips;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showChevron;

  @visibleForTesting
  static bool fitsOneRow({
    required BuildContext context,
    required double width,
    required String label,
    required String value,
    required bool chevron,
  }) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle? style) {
      final p = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    final inner = width - 2 * AppSpacing.lg;
    final chevronW = chevron ? AppSpacing.xs + 24 : 0;
    final valueMax = inner * 0.5 - chevronW;
    final valueW = measure(value, theme.textTheme.bodyLarge);
    if (valueW > valueMax) return false;
    final labelW = measure(label, detailLabelStyle(context));
    return labelW + AppSpacing.md + valueW + chevronW <= inner;
  }

  @override
  Widget build(BuildContext context) {
    final text = value;
    final many = valueChips;
    final hasWidget =
        valueWidget != null ||
        valueChip != null ||
        (many != null && many.isNotEmpty);
    if (text == null || text.isEmpty || hasWidget) {
      Widget? trailing = valueWidget ?? valueChip;
      if (trailing == null && many != null && many.isNotEmpty) {
        trailing = Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: many,
        );
      }
      if (trailing == null && text != null && text.isNotEmpty) {
        trailing = Text(text);
      }
      return DetailRow(
        label: label,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        showChevron: showChevron,
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final fits = fitsOneRow(
          context: context,
          width: box.maxWidth,
          label: label,
          value: text,
          chevron: showChevron,
        );
        if (fits) {
          return DetailRow(
            label: label,
            trailing: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: onTap,
            onLongPress: onLongPress,
            showChevron: showChevron,
          );
        }
        final stacked = DetailStacked(
          label: label,
          onLongPress: onTap == null ? onLongPress : null,
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ),
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  AppIcons.chevronRight,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        );
        if (onTap == null) return stacked;
        return InkWell(onTap: onTap, onLongPress: onLongPress, child: stacked);
      },
    );
  }
}
