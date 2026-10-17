import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../molecules/stepper_pill.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app_spacing.dart';

/// The meaning of a dot on a [MonthCalendar] day.
enum CalendarDot {
  income,
  expense,
  warning,
  neutral;

  Color resolve(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return switch (this) {
      income => palette.income,
      expense => palette.expense,
      warning => palette.warning,
      neutral => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}

/// A month grid (Mon–Sun) with coloured dots under the days that have
/// something, a selected day and the `‹ ตุลาคม 2026 ›` stepper above it.
/// Generic: the page feeds the data in — [dots] maps a day of the month to
/// the colours of its dots (at most three are drawn); [selected] / [onSelect]
/// pick a day; [onMonthChanged] gets the first day of the new month.
///
/// Nothing is fetched or computed here; the weekday initials follow the
/// ambient locale.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.month,
    required this.onMonthChanged,
    this.dots = const {},
    this.selected,
    this.onSelect,
    this.today,
    super.key,
  });

  /// Any day of the shown month.
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  /// Day of the month (1-31) → the kinds of its dots.
  final Map<int, List<CalendarDot>> dots;

  /// The picked day (ignored when it is not in [month]).
  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;

  /// Marked with an outline; null = no mark.
  final DateTime? today;

  static const _maxDots = 3;

  bool _same(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final first = DateTime(month.year, month.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    // Monday = 1: the blanks before the 1st.
    final lead = first.weekday - 1;
    final cells = lead + days;
    final rows = (cells / 7).ceil();
    // A known Monday for the weekday initials.
    final monday = DateTime(2024, 1, 1);
    final initials = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(monday.add(Duration(days: i))),
    ];

    Widget cell(int index) {
      final day = index - lead + 1;
      if (day < 1 || day > days) return const Expanded(child: SizedBox());
      final date = DateTime(month.year, month.month, day);
      final isSelected = _same(selected, date);
      final isToday = _same(today, date);
      final colors = (dots[day] ?? const []).take(_maxDots).toList();
      return Expanded(
        child: InkWell(
          key: ValueKey('calendarDay:$day'),
          borderRadius: BorderRadius.circular(12),
          onTap: onSelect == null ? null : () => onSelect!(date),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? scheme.primary : null,
                    border: isToday && !isSelected
                        ? Border.all(color: scheme.primary)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: text.bodyMedium?.copyWith(
                      color: isSelected ? scheme.onPrimary : null,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final c in colors)
                        Container(
                          key: ValueKey('calendarDot:$day'),
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: c.resolve(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: StepperPill.month(value: month, onChanged: onMonthChanged),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final i in initials)
              Expanded(
                child: Center(
                  child: Text(
                    i,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var r = 0; r < rows; r++)
          Row(children: [for (var c = 0; c < 7; c++) cell(r * 7 + c)]),
      ],
    );
  }
}
