import 'package:flutter/material.dart';

import 'recurrence_rule.dart';

/// What the repeat sheet holds, and how it turns into a rule. Two modes,
/// either-or: a repeat (ทุก N วัน / สัปดาห์ / เดือน / ปี on several weekdays,
/// days of the month, months) or picked dates (no end). [simple] = a budget's
/// or a goal's period: one start weekday / day instead of several.
class RecurrenceChoices {
  RecurrenceChoices(RecurrenceRule initial, {required this.simple}) {
    final rule = normalize(initial);
    final start = DateTime(rule.start.year, rule.start.month, rule.start.day);
    base = start;
    pickDates = !simple && initial.freq == RecurrenceFreq.dates;
    dates = {for (final d in initial.dates) DateTime(d.year, d.month, d.day)};
    freq = rule.freq == RecurrenceFreq.dates
        ? RecurrenceFreq.monthly
        : rule.freq;
    interval = rule.interval.clamp(1, 99);
    weekdays = {
      for (final d in rule.weekdays)
        if (d >= 1 && d <= 7) d,
    };
    if (weekdays.isEmpty) weekdays = {start.weekday};
    monthDays = {
      for (final d in rule.monthDays)
        if (d == RecurrenceRule.lastDay || (d >= 1 && d <= 31)) d,
    };
    if (monthDays.isEmpty) monthDays = {start.day};
    months = {
      for (final m in rule.months)
        if (m >= 1 && m <= 12) m,
    };
    if (months.isEmpty) months = {start.month};
    nthWeekday = rule.monthly;

    // a period (simple): its start weekday / day
    startWeekday = start.weekday;
    monthDay =
        rule.monthDays.length == 1 &&
            rule.monthDays.first != RecurrenceRule.lastDay
        ? rule.monthDays.first
        : start.day;
    yearMonth = start.month;
    yearDay = start.day.clamp(1, daysIn(start.month));

    final end = rule.end;
    endKind = end.kind;
    final date = end.date;
    endDate = date == null
        ? DateTime(start.year, start.month + 1, start.day)
        : DateTime(date.year, date.month, date.day);
    if (endDate.isBefore(start)) endDate = start;
    final last = lastEndOf(rule.start);
    if (endDate.isAfter(last)) endDate = last;
    endCount = (end.count ?? 12).clamp(1, 999);
  }

  static const endSpanYears = 2;

  final bool simple;

  /// The start the sheet opened with; a moved start is always worked out
  /// from here, so picking the old day again puts it back.
  late final DateTime base;

  /// เลือกวันเอง: the rule is the picked [dates] (no end).
  late bool pickDates;
  late Set<DateTime> dates;
  late RecurrenceFreq freq;
  late int interval;
  late Set<int> weekdays;

  /// Days of a monthly / yearly rule (1–31, [RecurrenceRule.lastDay]).
  late Set<int> monthDays;

  /// Months of a yearly rule.
  late Set<int> months;

  /// A monthly nth-weekday rule kept as it came (not offered on screen);
  /// picking a day drops it.
  RecurrenceMonthly? nthWeekday;
  late int startWeekday;
  late int monthDay;
  late int yearMonth;
  late int yearDay;
  late RecurrenceEndKind endKind;
  late DateTime endDate;
  late int endCount;

  static RecurrenceRule normalize(RecurrenceRule r) =>
      r.copyWith(interval: r.interval < 1 ? 1 : r.interval);

  static DateTime lastEndOf(DateTime start) =>
      DateTime(start.year + endSpanYears, start.month, start.day);

  /// Days in [month] of a common year: a yearly day never lands on 29 Feb.
  static int daysIn(int month) => DateTime(2001, month + 1, 0).day;

  /// Where the first round lands. A period (simple) starts on the picked
  /// weekday / day / date, so it moves to the next such day on or after
  /// [base]; a repeat starts on [base].
  DateTime anchoredStart() {
    final b = base;
    if (!simple) return b;
    switch (freq) {
      case RecurrenceFreq.weekly:
        return DateTime(
          b.year,
          b.month,
          b.day + (startWeekday - b.weekday) % 7,
        );
      case RecurrenceFreq.monthly:
        for (var k = 0; k < 12; k++) {
          final last = DateTime(b.year, b.month + k + 1, 0).day;
          final day = monthDay >= 31 ? last : monthDay;
          if (day > last) continue;
          final d = DateTime(b.year, b.month + k, day);
          if (!d.isBefore(b)) return d;
        }
        return b;
      case RecurrenceFreq.yearly:
        final d = DateTime(b.year, yearMonth, yearDay);
        return d.isBefore(b) ? DateTime(b.year + 1, yearMonth, yearDay) : d;
      default:
        return b;
    }
  }

  RecurrenceRule build() {
    if (pickDates) {
      final sorted = dates.toList()..sort();
      return RecurrenceRule(
        freq: RecurrenceFreq.dates,
        start: sorted.isEmpty ? base : sorted.first,
        dates: sorted,
      );
    }
    final repeat = !simple;
    return RecurrenceRule(
      freq: freq,
      start: anchoredStart(),
      interval: interval,
      weekdays: freq == RecurrenceFreq.weekly && repeat
          ? {...weekdays}
          : const {},
      monthly: freq == RecurrenceFreq.monthly && repeat ? nthWeekday : null,
      monthDays:
          repeat &&
              (freq == RecurrenceFreq.yearly ||
                  (freq == RecurrenceFreq.monthly && nthWeekday == null))
          ? {...monthDays}
          : const {},
      months: repeat && freq == RecurrenceFreq.yearly ? {...months} : const {},
      end: switch (endKind) {
        RecurrenceEndKind.never => const RecurrenceEnd.never(),
        RecurrenceEndKind.onDate => RecurrenceEnd.onDate(endDate),
        RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(endCount),
      },
    );
  }

  /// Applies [change] to the choices and returns the rule they now make.
  RecurrenceRule edit(VoidCallback change) {
    change();
    final start = anchoredStart();
    if (endDate.isBefore(start)) endDate = start;
    return build();
  }

  /// Flips [d]; the last weekday left on stays on. Returns null then.
  RecurrenceRule? toggleWeekday(int d) {
    if (weekdays.contains(d) && weekdays.length == 1) return null;
    return edit(() {
      weekdays = {...weekdays};
      weekdays.contains(d) ? weekdays.remove(d) : weekdays.add(d);
    });
  }

  /// Flips a day of the month ([RecurrenceRule.lastDay] = สิ้นเดือน); the
  /// last one left stays on. Picking a day drops a kept nth-weekday pattern.
  RecurrenceRule? toggleMonthDay(int d) {
    if (nthWeekday == null && monthDays.contains(d) && monthDays.length == 1) {
      return null;
    }
    return edit(() {
      if (nthWeekday != null) {
        nthWeekday = null;
        monthDays = {d};
        return;
      }
      monthDays = {...monthDays};
      monthDays.contains(d) ? monthDays.remove(d) : monthDays.add(d);
    });
  }

  /// Flips a month of a yearly rule; the last one left stays on.
  RecurrenceRule? toggleMonth(int m) {
    if (months.contains(m) && months.length == 1) return null;
    return edit(() {
      months = {...months};
      months.contains(m) ? months.remove(m) : months.add(m);
    });
  }

  /// Flips a picked date (เลือกวันเอง).
  RecurrenceRule toggleDate(DateTime day) => edit(() {
    final d = DateTime(day.year, day.month, day.day);
    dates = {...dates};
    if (!dates.remove(d)) dates.add(d);
  });
}
