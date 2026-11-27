import 'package:flutter/foundation.dart';

enum RecurrenceFreq { daily, weekly, monthly, yearly, dates }

enum RecurrenceMonthlyMode { day, weekday }

/// A monthly rule's nth-weekday pattern ("พุธที่ 4"): kept in the model, not
/// offered on screen. The days of a monthly / yearly rule are
/// [RecurrenceRule.monthDays].
@immutable
class RecurrenceMonthly {
  const RecurrenceMonthly.onWeekday({
    required int this.nth,
    required int this.weekday,
  }) : mode = RecurrenceMonthlyMode.weekday;

  static const lastWeek = -1;

  final RecurrenceMonthlyMode mode;
  final int? nth;
  final int? weekday;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceMonthly &&
      other.mode == mode &&
      other.nth == nth &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(mode, nth, weekday);

  @override
  String toString() => 'RecurrenceMonthly($mode, nth: $nth, weekday: $weekday)';
}

@immutable
class RecurrenceEnd {
  const RecurrenceEnd.never()
    : kind = RecurrenceEndKind.never,
      date = null,
      count = null;

  const RecurrenceEnd.onDate(DateTime this.date)
    : kind = RecurrenceEndKind.onDate,
      count = null;

  const RecurrenceEnd.afterCount(int this.count)
    : kind = RecurrenceEndKind.afterCount,
      date = null;

  final RecurrenceEndKind kind;

  final DateTime? date;

  final int? count;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceEnd &&
      other.kind == kind &&
      other.date == date &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, date, count);

  @override
  String toString() => switch (kind) {
    RecurrenceEndKind.never => 'RecurrenceEnd.never()',
    RecurrenceEndKind.onDate => 'RecurrenceEnd.onDate($date)',
    RecurrenceEndKind.afterCount => 'RecurrenceEnd.afterCount($count)',
  };
}

enum RecurrenceEndKind { never, onDate, afterCount }

@immutable
class RecurrenceRule {
  const RecurrenceRule({
    required this.freq,
    required this.start,
    this.interval = 1,
    this.weekdays = const {},
    this.monthly,
    this.monthDays = const {},
    this.months = const {},
    this.dates = const [],
    this.end = const RecurrenceEnd.never(),
  });

  final RecurrenceFreq freq;
  final int interval;
  final Set<int> weekdays;

  /// The nth-weekday pattern of a monthly rule (null = by [monthDays]).
  final RecurrenceMonthly? monthly;

  /// The days of a monthly / yearly rule: 1–31, [lastDay] = สิ้นเดือน (a day
  /// past a short month's end falls on its last day). Empty = the start's day.
  final Set<int> monthDays;

  /// The months of a yearly rule (1–12). Empty = the start's month.
  final Set<int> months;

  static const lastDay = -1;
  final List<DateTime> dates;
  final DateTime start;
  final RecurrenceEnd end;

  RecurrenceRule copyWith({
    RecurrenceFreq? freq,
    int? interval,
    Set<int>? weekdays,
    RecurrenceMonthly? monthly,
    bool clearMonthly = false,
    Set<int>? monthDays,
    Set<int>? months,
    List<DateTime>? dates,
    DateTime? start,
    RecurrenceEnd? end,
  }) => RecurrenceRule(
    freq: freq ?? this.freq,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthly: clearMonthly ? null : (monthly ?? this.monthly),
    monthDays: monthDays ?? this.monthDays,
    months: months ?? this.months,
    dates: dates ?? this.dates,
    start: start ?? this.start,
    end: end ?? this.end,
  );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.freq == freq &&
      other.interval == interval &&
      setEquals(other.weekdays, weekdays) &&
      other.monthly == monthly &&
      setEquals(other.monthDays, monthDays) &&
      setEquals(other.months, months) &&
      listEquals(other.dates, dates) &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(
    freq,
    interval,
    Object.hashAllUnordered(weekdays),
    monthly,
    Object.hashAllUnordered(monthDays),
    Object.hashAllUnordered(months),
    Object.hashAll(dates),
    start,
    end,
  );

  @override
  String toString() =>
      'RecurrenceRule($freq, interval: $interval, weekdays: $weekdays, '
      'monthly: $monthly, monthDays: $monthDays, months: $months, dates: $dates, '
      'start: $start, end: $end)';
}
