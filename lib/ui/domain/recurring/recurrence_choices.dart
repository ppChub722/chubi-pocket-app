import 'package:flutter/material.dart';

import 'recurrence_rule.dart';

/// What the repeat sheet's chips hold, and how they turn into a rule.
class RecurrenceChoices {
  RecurrenceChoices(RecurrenceRule initial, {required this.simple}) {
    final rule = normalize(initial);
    final start = DateTime(rule.start.year, rule.start.month, rule.start.day);
    base = start;
    freq = rule.freq;
    interval = rule.interval.clamp(1, 99);
    weekdays = {
      for (final d in rule.weekdays)
        if (d >= 1 && d <= 7) d,
    };
    if (weekdays.isEmpty) weekdays = {start.weekday};
    startWeekday = start.weekday;
    yearMonth = start.month;
    yearDay = start.day.clamp(1, daysIn(start.month));

    final m = rule.monthly;
    monthlyMode = m?.mode ?? RecurrenceMonthlyMode.day;
    final day = (m?.mode == RecurrenceMonthlyMode.day ? m?.day : null);
    monthDay = (day ?? start.day).clamp(1, RecurrenceMonthly.lastDay);
    final weekdayMode = m?.mode == RecurrenceMonthlyMode.weekday;
    final startNth = (start.day - 1) ~/ 7 + 1;
    nth = (weekdayMode ? m?.nth : null) ?? startNth;
    if (nth >= 5) nth = RecurrenceMonthly.lastWeek;
    nthWeekday = (weekdayMode ? m?.weekday : null) ?? start.weekday;

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
  late RecurrenceFreq freq;
  late int interval;
  late Set<int> weekdays;
  late int startWeekday;
  late RecurrenceMonthlyMode monthlyMode;
  late int monthDay;
  late int nth;
  late int nthWeekday;
  late int yearMonth;
  late int yearDay;
  late RecurrenceEndKind endKind;
  late DateTime endDate;
  late int endCount;

  static RecurrenceRule normalize(RecurrenceRule r) {
    final dates = r.freq == RecurrenceFreq.dates;
    return r.copyWith(
      freq: dates ? RecurrenceFreq.monthly : null,
      dates: dates ? const [] : null,
      interval: r.interval < 1 ? 1 : r.interval,
    );
  }

  static DateTime lastEndOf(DateTime start) =>
      DateTime(start.year + endSpanYears, start.month, start.day);

  /// Days in [month] of a common year: a yearly day never lands on 29 Feb.
  static int daysIn(int month) => DateTime(2001, month + 1, 0).day;

  /// Where the first round lands. A yearly rule repeats on its start, and a
  /// budget's periods (simple) start on the picked weekday or day, so both
  /// move the start to the next such day on or after [base].
  DateTime anchoredStart() {
    final b = base;
    if (freq == RecurrenceFreq.yearly) {
      final d = DateTime(b.year, yearMonth, yearDay);
      return d.isBefore(b) ? DateTime(b.year + 1, yearMonth, yearDay) : d;
    }
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
          final day = monthDay >= RecurrenceMonthly.lastDay ? last : monthDay;
          if (day > last) continue;
          final d = DateTime(b.year, b.month + k, day);
          if (!d.isBefore(b)) return d;
        }
        return b;
      default:
        return b;
    }
  }

  RecurrenceRule build() => RecurrenceRule(
    freq: freq,
    start: anchoredStart(),
    interval: interval,
    weekdays: freq == RecurrenceFreq.weekly && !simple
        ? {...weekdays}
        : const {},
    monthly: freq != RecurrenceFreq.monthly || simple
        ? null
        : (monthlyMode == RecurrenceMonthlyMode.day
              ? RecurrenceMonthly.onDay(monthDay)
              : RecurrenceMonthly.onWeekday(nth: nth, weekday: nthWeekday)),
    end: switch (endKind) {
      RecurrenceEndKind.never => const RecurrenceEnd.never(),
      RecurrenceEndKind.onDate => RecurrenceEnd.onDate(endDate),
      RecurrenceEndKind.afterCount => RecurrenceEnd.afterCount(endCount),
    },
  );

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
}
