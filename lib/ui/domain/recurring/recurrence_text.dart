import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'recurrence_rule.dart';

const _sep = ' · ';

/// A [RecurrenceRule] in words (Google Calendar style):
///
/// - daily: "ทุกวัน" / "ทุก 2 วัน"
/// - weekly: "ทุกวันจันทร์" / "ทุกวันจันทร์และพุธ" /
///   "ทุก 2 สัปดาห์ · วันจันทร์"
/// - monthly by day: "ทุกวันที่ 3" / "ทุกวันสุดท้ายของเดือน" /
///   "ทุก 3 เดือน · วันที่ 3"
/// - monthly by weekday: "ทุกวันจันทร์ที่ 2 ของเดือน" /
///   "ทุกวันศุกร์สุดท้ายของเดือน" / "ทุก 2 เดือน · วันจันทร์ที่ 2"
/// - yearly: "ทุกปี 3 ต.ค." / "ทุก 2 ปี · 3 ต.ค."
/// - hand-picked dates: "กำหนดเอง 5 วัน"
///
/// [showEnd] appends the end ("· 12 ครั้ง" / "· ถึง 3 ต.ค. 2027"; nothing
/// for never). [seq] + [total] (both set) append the progress "· 4/12".
/// [localeCode] null = the localizations' locale.
String recurrenceLabel(
  AppLocalizations l,
  RecurrenceRule rule, {
  int? seq,
  int? total,
  bool showEnd = false,
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
      final names = _joinNames(l, [for (final d in days) _weekdayName(l, d)]);
      return n == 1
          ? l.recurEveryWeekdays(names)
          : '${l.recurEveryWeeks(n)}$_sep${l.recurOnWeekdays(names)}';
    }(),
    RecurrenceFreq.monthly => _monthly(l, rule, n),
    RecurrenceFreq.yearly => () {
      final date = DateFormat.MMMd(
        locale,
      ).format(DateTime(2000, start.month, start.day));
      return n == 1
          ? l.recurYearlyOn(date)
          : '${l.recurEveryYears(n)}$_sep$date';
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

String _monthly(AppLocalizations l, RecurrenceRule rule, int n) {
  final start = rule.start;
  final m = rule.monthly ?? RecurrenceMonthly.onDay(start.day);
  switch (m.mode) {
    case RecurrenceMonthlyMode.day:
      final day = m.day ?? start.day;
      final last = day >= RecurrenceMonthly.lastDay;
      if (n == 1) {
        return last ? l.recurMonthlyLastDay : l.recurMonthlyOnDay(day);
      }
      return '${l.recurEveryMonths(n)}$_sep'
          '${last ? l.recurLastDay : l.recurOnDay(day)}';
    case RecurrenceMonthlyMode.weekday:
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
}

/// The select key the English ordinal strings switch on.
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

/// "จันทร์" · "จันทร์และพุธ" · "จันทร์ พุธ และศุกร์".
String _joinNames(AppLocalizations l, List<String> names) {
  if (names.length == 1) return names.single;
  if (names.length == 2) return l.recurWeekdayPair(names[0], names[1]);
  return l.recurWeekdayList(
    names.sublist(0, names.length - 1).join(l.recurWeekdayListSep),
    names.last,
  );
}

/// A [RecurrenceRule] as one ellipsised line — [recurrenceLabel] (see it
/// for the wording, [seq] / [total] progress and [showEnd]). [style] null =
/// `bodySmall` in the muted meta colour.
class RecurrenceText extends StatelessWidget {
  const RecurrenceText({
    required this.rule,
    this.seq,
    this.total,
    this.showEnd = false,
    this.style,
    super.key,
  });

  final RecurrenceRule rule;
  final int? seq;
  final int? total;
  final bool showEnd;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Text(
      recurrenceLabel(l, rule, seq: seq, total: total, showEnd: showEnd),
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
