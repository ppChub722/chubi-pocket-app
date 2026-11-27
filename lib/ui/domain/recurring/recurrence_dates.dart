import 'recurrence_rule.dart';

/// The dates a rule makes, as the BE's engine (shared/recurrence) makes them:
/// several weekdays, days of the month (−1 = the last day; a day past a short
/// month's end falls on its last day; a date is made once), months × days,
/// picked dates. [until] caps the walk; the end cuts it (a count from the
/// start). At most [limit] dates (0 = no cap; a safety stop at 1000).
List<DateTime> recurrenceDates(
  RecurrenceRule r, {
  required DateTime until,
  int limit = 0,
}) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final start = day(r.start);
  var cap = day(until);
  final end = r.end;
  if (end.kind == RecurrenceEndKind.onDate && end.date != null) {
    final e = day(end.date!);
    if (e.isBefore(cap)) cap = e;
  }
  final max = end.kind == RecurrenceEndKind.afterCount && end.count != null
      ? end.count!
      : 0;
  final out = <DateTime>[];
  bool full() =>
      (limit > 0 && out.length >= limit) ||
      (max > 0 && out.length >= max) ||
      out.length >= 1000;
  // false = stop the walk
  bool add(DateTime d) {
    if (d.isAfter(cap)) return false;
    if (!d.isBefore(start)) out.add(d);
    return !full();
  }

  int lastOf(int y, int m) => DateTime(y, m + 1, 0).day;
  List<DateTime> daysIn(int y, int m) {
    final ld = lastOf(y, m);
    final days = r.monthDays.isEmpty ? {start.day} : r.monthDays;
    final nums = {
      for (final d in days) (d == RecurrenceRule.lastDay || d > ld) ? ld : d,
    }.where((d) => d >= 1).toList()..sort();
    return [for (final d in nums) DateTime(y, m, d)];
  }

  final n = r.interval < 1 ? 1 : r.interval;
  switch (r.freq) {
    case RecurrenceFreq.daily:
      for (var d = start; ; d = DateTime(d.year, d.month, d.day + n)) {
        if (!add(d)) break;
      }
    case RecurrenceFreq.weekly:
      final days = (r.weekdays.isEmpty ? {start.weekday} : r.weekdays).toList()
        ..sort();
      final monday = DateTime(
        start.year,
        start.month,
        start.day - (start.weekday - 1),
      );
      weeks:
      for (var w = monday; ; w = DateTime(w.year, w.month, w.day + 7 * n)) {
        for (final wd in days) {
          if (!add(DateTime(w.year, w.month, w.day + wd - 1))) break weeks;
        }
        if (w.isAfter(cap)) break;
      }
    case RecurrenceFreq.monthly:
      months:
      for (var k = 0; ; k += n) {
        final first = DateTime(start.year, start.month + k);
        if (first.isAfter(cap)) break;
        final m = r.monthly;
        final ds = m != null && m.mode == RecurrenceMonthlyMode.weekday
            ? [
                ?_nthWeekday(
                  first.year,
                  first.month,
                  m.nth ?? 1,
                  m.weekday ?? 1,
                ),
              ]
            : daysIn(first.year, first.month);
        for (final d in ds) {
          if (!add(d)) break months;
        }
      }
    case RecurrenceFreq.yearly:
      final ms = (r.months.isEmpty ? {start.month} : r.months).toList()..sort();
      years:
      for (var k = 0; ; k += n) {
        final y = start.year + k;
        if (DateTime(y).isAfter(cap)) break;
        for (final m in ms) {
          for (final d in daysIn(y, m)) {
            if (!add(d)) break years;
          }
        }
      }
    case RecurrenceFreq.dates:
      final ds = {for (final d in r.dates) day(d)}.toList()..sort();
      for (final d in ds) {
        if (!add(d)) break;
      }
  }
  return out;
}

DateTime? _nthWeekday(int y, int m, int nth, int weekday) {
  if (nth == RecurrenceMonthly.lastWeek) {
    var d = DateTime(y, m + 1, 0);
    while (d.weekday != weekday) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return d;
  }
  var d = DateTime(y, m);
  while (d.weekday != weekday) {
    d = DateTime(d.year, d.month, d.day + 1);
  }
  d = DateTime(d.year, d.month, d.day + 7 * (nth - 1));
  return d.month == m ? d : null;
}
