import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../atoms/app_chip.dart';
import '../organisms/app_sheet.dart';
import '../organisms/picker_sheet.dart';
import '../atoms/busy_scope.dart';

const int kLastDayOfMonth = 31;

class DayOfMonthPick {
  const DayOfMonthPick(this.day);
  final int? day;
}

String dayOfMonthLabel(BuildContext context, int? day) {
  final l = UiConfig.stringsOf(context);
  return switch (day) {
    null => l.dayNone,
    kLastDayOfMonth => l.dayLast,
    final d => l.dayEveryMonth(d),
  };
}

Future<DayOfMonthPick?> showDayOfMonthPicker(
  BuildContext context, {
  required String title,
  int? selected,
  bool allowNone = true,
}) {
  return showAppSheetCustom<DayOfMonthPick>(
    context,
    builder: (_) => PickerSheet(
      title: title,
      builder: (context, _) => DayOfMonthGrid(
        selected: selected,
        allowNone: allowNone,
        onPicked: (d) => Navigator.of(context).pop(DayOfMonthPick(d)),
      ),
    ),
  );
}

class DayOfMonthGrid extends StatelessWidget {
  const DayOfMonthGrid({
    required this.onPicked,
    this.selected,
    this.allowNone = true,
    this.days = kLastDayOfMonth,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    super.key,
  });

  final int? selected;
  final bool allowNone;
  final ValueChanged<int?> onPicked;

  /// How many days to offer. The default ends on a "Last" cell (any month's
  /// last day); fewer days list plain numbers, for a known month.
  final int days;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l = UiConfig.stringsOf(context);
    final withLast = days >= kLastDayOfMonth;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.xs,
            crossAxisSpacing: AppSpacing.xs,
            children: [
              for (var d = 1; d <= (withLast ? kLastDayOfMonth - 1 : days); d++)
                _DayCell(
                  label: '$d',
                  selected: d == selected,
                  onTap: () => onPicked(d),
                ),
              if (withLast)
                _DayCell(
                  label: l.dayLastShort,
                  selected: selected == kLastDayOfMonth,
                  onTap: () => onPicked(kLastDayOfMonth),
                  semantics: l.dayLast,
                ),
            ],
          ),
          if (allowNone) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppChip(
                  label: l.dayNone,
                  selected: selected == null,
                  onTap: () => onPicked(null),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semantics,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semantics,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: BusyLock(
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
