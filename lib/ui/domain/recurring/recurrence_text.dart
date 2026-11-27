import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'recurrence_rule.dart';

const _sep = ' · ';

/// A rule in words. [compact] = a chip (mock RepeatRows: "ทุกวันที่ 8, 16, 25",
/// more than 3 days → "+n", "ทุก จ. พ.", "ทุกปี 25 ม.ค. เม.ย."); else the
/// repeat sheet's sentence ("ทุกเดือน วันที่ 8, 16 และ 25").
String recurrenceLabel(
  AppLocalizations l,
  RecurrenceRule rule, {
  int? seq,
  int? total,
  bool showEnd = false,
  bool compact = false,
  String? localeCode,
}) {
  final locale = localeCode ?? l.localeName;
  final n = rule.interval < 1 ? 1 : rule.interval;
  final start = rule.start;

  final base = switch (rule.freq) {
    RecurrenceFreq.daily => l.recurEveryDays(n),
    RecurrenceFreq.weekly => () {
      final days =
          (rule.weekdays.isEmpty ? {start.weekday} : rule.weekdays)
              .where((d) => d >= 1 && d <= 7)
              .toList()
            ..sort();
      if (compact) {
        final names = [
          for (final d in days) _weekdayShort(locale, d),
        ].join(' ');
        return n == 1
            ? '${l.recurSheetEvery} $names'
            : '${l.recurEveryWeeks(n)}$_sep$names';
      }
      final names = _joinNames(l, [for (final d in days) _weekdayName(l, d)]);
      return n == 1
          ? l.recurEveryWeekdays(names)
          : '${l.recurEveryWeeks(n)}$_sep${l.recurOnWeekdays(names)}';
    }(),
    RecurrenceFreq.monthly => _monthly(l, rule, n, compact),
    RecurrenceFreq.yearly => () {
      final months =
          (rule.months.isEmpty ? {start.month} : rule.months).toList()..sort();
      final monthNames = [
        for (final m in months)
          DateFormat.MMM(locale).format(DateTime(2001, m)),
      ];
      final days = _dayList(l, rule.monthDays, start.day, compact: true);
      if (compact || (months.length == 1 && rule.monthDays.length <= 1)) {
        final text = '$days ${monthNames.join(' ')}';
        return n == 1
            ? l.recurYearlyOn(text)
            : '${l.recurEveryYears(n)}$_sep$text';
      }
      final text = l.recurYearlyOnMonths(
        _dayList(l, rule.monthDays, start.day),
        monthNames.join(', '),
      );
      return n == 1 ? text : '${l.recurEveryYears(n)}$_sep$text';
    }(),
    RecurrenceFreq.dates => l.recurCustomDates(rule.dates.length),
  };

  final parts = [base];
  if (showEnd) {
    final end = rule.end;
    switch (end.kind) {
      case RecurrenceEndKind.never:
        break;
      case RecurrenceEndKind.afterCount:
        parts.add(l.recurEndCount(end.count!));
      case RecurrenceEndKind.onDate:
        parts.add(l.recurEndUntil(DateFormat.yMMMd(locale).format(end.date!)));
    }
  }
  if (seq != null && total != null) parts.add('$seq/$total');
  return parts.join(_sep);
}

/// The days of a monthly / yearly rule: "8, 16 และ 25" (compact: "8, 16, 25",
/// over 3 → "1, 8, 15 +2"); [RecurrenceRule.lastDay] = สิ้นเดือน, last.
String _dayList(
  AppLocalizations l,
  Set<int> days,
  int startDay, {
  bool compact = false,
}) {
  final set = days.isEmpty ? {startDay} : days;
  final nums = set.where((d) => d != RecurrenceRule.lastDay).toList()..sort();
  final words = [
    for (final d in nums) '$d',
    if (set.contains(RecurrenceRule.lastDay)) l.recurLastDayShort,
  ];
  if (compact) {
    if (words.length <= 3) return words.join(', ');
    return '${words.take(3).join(', ')} ${l.recurDaysMore(words.length - 3)}';
  }
  if (words.length == 1) return words.single;
  return l.recurNumberList(
    words.sublist(0, words.length - 1).join(', '),
    words.last,
  );
}

String _monthly(AppLocalizations l, RecurrenceRule rule, int n, bool compact) {
  final start = rule.start;
  final m = rule.monthly;
  if (m != null && m.mode == RecurrenceMonthlyMode.weekday) {
    final nth = m.nth ?? ((start.day - 1) ~/ 7 + 1);
    final name = _weekdayName(l, m.weekday ?? start.weekday);
    final last = nth == RecurrenceMonthly.lastWeek;
    final ord = _ordinal(nth);
    if (n == 1) {
      return last
          ? l.recurMonthlyLastWeekday(name)
          : l.recurMonthlyNthWeekday(ord, nth, name);
    }
    return '${l.recurEveryMonths(n)}$_sep'
        '${last ? l.recurOnLastWeekday(name) : l.recurOnNthWeekday(ord, nth, name)}';
  }
  final days = rule.monthDays.isEmpty ? {start.day} : rule.monthDays;
  final onlyLast = days.length == 1 && days.first == RecurrenceRule.lastDay;
  if (n == 1) {
    if (onlyLast) return l.recurMonthlyLastDay;
    final list = _dayList(l, days, start.day, compact: compact);
    return compact
        ? l.recurMonthlyOnDays(list)
        : '${l.recurEveryMonths(1)} ${l.recurOnDays(list)}';
  }
  return '${l.recurEveryMonths(n)}$_sep'
      '${onlyLast ? l.recurLastDayShort : l.recurOnDays(_dayList(l, days, start.day, compact: compact))}';
}

String _ordinal(int nth) => switch (nth) {
  1 => 'first',
  2 => 'second',
  3 => 'third',
  4 => 'fourth',
  _ => 'other',
};

String _weekdayName(AppLocalizations l, int isoWeekday) => switch (isoWeekday) {
  1 => l.recurWeekday1,
  2 => l.recurWeekday2,
  3 => l.recurWeekday3,
  4 => l.recurWeekday4,
  5 => l.recurWeekday5,
  6 => l.recurWeekday6,
  _ => l.recurWeekday7,
};

/// "จ." / "Mon": the locale's short weekday name.
String _weekdayShort(String locale, int isoWeekday) =>
    DateFormat.E(locale).format(DateTime(2024, 1, isoWeekday));

String _joinNames(AppLocalizations l, List<String> names) {
  if (names.length == 1) return names.single;
  if (names.length == 2) return l.recurWeekdayPair(names[0], names[1]);
  return l.recurWeekdayList(
    names.sublist(0, names.length - 1).join(l.recurWeekdayListSep),
    names.last,
  );
}

class RecurrenceText extends StatelessWidget {
  const RecurrenceText({
    required this.rule,
    this.seq,
    this.total,
    this.showEnd = false,
    this.compact = false,
    this.style,
    super.key,
  });

  final RecurrenceRule rule;
  final int? seq;
  final int? total;
  final bool showEnd;
  final bool compact;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Text(
      recurrenceLabel(
        l,
        rule,
        seq: seq,
        total: total,
        showEnd: showEnd,
        compact: compact,
      ),
      style:
          style ??
          Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
