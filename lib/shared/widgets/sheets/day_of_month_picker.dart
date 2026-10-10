import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../chips/pill.dart';
import 'app_sheet.dart';
import 'picker_sheet.dart';

/// The day that means "the last day of the month". The BE clamps it (31 →
/// Apr 30, Feb 28/29), so the grid stops at 30 and this is its own choice —
/// a stored 31 always reads as วันสุดท้ายของเดือน.
const int kLastDayOfMonth = 31;

/// What [showDayOfMonthPicker] resolves to — `null` = dismissed. [day] null
/// = ไม่ระบุ; [kLastDayOfMonth] = the last day.
class DayOfMonthPick {
  const DayOfMonthPick(this.day);
  final int? day;
}

/// "วันที่ 15 ของทุกเดือน" / "วันสุดท้ายของเดือน" / "ไม่ระบุ" — how a
/// stored day-of-month reads anywhere (fields, detail rows).
String dayOfMonthLabel(AppLocalizations l, int? day) => switch (day) {
  null => l.dayPickerNone,
  kLastDayOfMonth => l.dayPickerLastDay,
  final d => l.dayPickerEveryMonth(d),
};

/// A day of the month (statement day, due day) on the kit [PickerSheet]
/// shell: title + ✕, a calendar-style 7-column grid of 1–30, then
/// [วันสุดท้ายของเดือน] and, when [allowNone], [ไม่ระบุ]. The current one is
/// highlighted — a filled circle in the grid, a selected pill below; never
/// a ✓.
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

/// The day picker's body, for embedding outside [showDayOfMonthPicker].
/// [onPicked] gets 1–30, [kLastDayOfMonth], or null (ไม่ระบุ).
class DayOfMonthGrid extends StatelessWidget {
  const DayOfMonthGrid({
    required this.onPicked,
    this.selected,
    this.allowNone = true,
    super.key,
  });

  final int? selected;
  final bool allowNone;
  final ValueChanged<int?> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
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
              for (var d = 1; d < kLastDayOfMonth; d++)
                _DayCell(
                  day: d,
                  selected: d == selected,
                  onTap: () => onPicked(d),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoicePill(
                label: l.dayPickerLastDay,
                selected: selected == kLastDayOfMonth,
                onTap: () => onPicked(kLastDayOfMonth),
              ),
              if (allowNone)
                ChoicePill(
                  label: l.dayPickerNone,
                  selected: selected == null,
                  onTap: () => onPicked(null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One day: a circle — filled primary when [selected], else a quiet tint
/// (the month grid's cell colours).
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              '$day',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
