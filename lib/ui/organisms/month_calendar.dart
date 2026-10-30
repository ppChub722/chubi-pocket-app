import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../atoms/app_chip.dart';
import '../molecules/stepper_pill.dart';
import '../tokens/app/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/hero_colors.dart';

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

/// A short line under a day's number ("-419", "+35,000", "?") in its tone.
@immutable
class CalendarCaption {
  const CalendarCaption(this.text, {this.tone = CalendarDot.neutral});

  final String text;
  final CalendarDot tone;
}

/// The month as a grid, the week starting where the locale starts it. A day
/// with something on it gets a box, its dots (optional) and a [captions]
/// line; an [edges] day a border in its tone; [today] a plain outline; days
/// before it are muted; the weeks' ends show the next and previous months'
/// days greyed.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.month,
    required this.onMonthChanged,
    this.dots = const {},
    this.captions = const {},
    this.edges = const {},
    this.selected,
    this.onSelect,
    this.today,
    this.showStepper = true,
    super.key,
  });

  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  /// False when the page's own month stepper drives it (a hero above).
  final bool showStepper;

  final Map<int, List<CalendarDot>> dots;

  /// Day of the month → the line under its number.
  final Map<int, CalendarCaption> captions;

  /// Day of the month → its box's border colour (waiting = warning, the
  /// day's money out / in = expense / income). Today keeps its plain outline.
  final Map<int, CalendarDot> edges;

  final DateTime? selected;
  final ValueChanged<DateTime>? onSelect;

  final DateTime? today;

  static const _maxDots = 3;
  static const double _cellHeight = 50;

  bool _same(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hero = HeroColors.maybeOf(context);
    final muted = hero?.muted ?? scheme.onSurfaceVariant;
    final accent = hero?.accent ?? scheme.primary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 0 = Sunday, as DateTime.weekday % 7.
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final first = DateTime(month.year, month.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final lead = (first.weekday % 7 - firstWeekday + 7) % 7;
    final rows = ((lead + days) / 7).ceil();
    final sunday = DateTime(2024, 1, 7);
    final initials = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale)
            .format(sunday.add(Duration(days: firstWeekday + i)))
            .replaceAll('.', ''),
    ];
    final now = today;
    final todayDate = now == null
        ? null
        : DateTime(now.year, now.month, now.day);

    Widget cell(int index) {
      final date = DateTime(month.year, month.month, index - lead + 1);
      final inMonth = date.month == month.month;
      if (!inMonth) {
        return Expanded(
          child: SizedBox(
            height: _cellHeight,
            child: Center(
              child: Text(
                '${date.day}',
                style: text.bodyMedium?.copyWith(
                  color: muted.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        );
      }
      final day = date.day;
      final isSelected = _same(selected, date);
      final isToday = _same(today, date);
      final past = todayDate != null && date.isBefore(todayDate);
      final colors = (dots[day] ?? const []).take(_maxDots).toList();
      final caption = captions[day];
      final edge = edges[day]?.resolve(context);
      final busy = colors.isNotEmpty || caption != null || edge != null;
      final onAccent = AppChip.readableOn(accent, Colors.white);
      final fill = isSelected
          ? accent
          : busy
          ? (hero?.insetOrSoft ?? scheme.surfaceContainerHigh)
          : null;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: fill ?? Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: isSelected
                  ? BorderSide.none
                  : isToday
                  ? BorderSide(color: scheme.outline, width: 1.5)
                  : edge != null
                  ? BorderSide(color: edge, width: 1.5)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('calendarDay:$day'),
              onTap: onSelect == null ? null : () => onSelect!(date),
              child: SizedBox(
                height: _cellHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: text.bodyMedium?.copyWith(
                        color: isSelected
                            ? onAccent
                            : past
                            ? muted
                            : null,
                        fontWeight: isSelected || isToday || busy
                            ? FontWeight.w700
                            : null,
                      ),
                    ),
                    if (colors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (i, c) in colors.indexed)
                              Container(
                                key: i == 0
                                    ? ValueKey('calendarDot:$day')
                                    : null,
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? onAccent
                                      : c.resolve(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (caption != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            caption.text,
                            key: ValueKey('calendarCaption:$day'),
                            maxLines: 1,
                            style: text.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? onAccent
                                  : caption.tone.resolve(context),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showStepper) ...[
          Center(
            child: StepperPill.month(value: month, onChanged: onMonthChanged),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            for (final i in initials)
              Expanded(
                child: Center(
                  child: Text(
                    i,
                    style: text.labelSmall?.copyWith(color: muted),
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
