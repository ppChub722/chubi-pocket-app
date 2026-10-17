import 'package:flutter/foundation.dart';

enum RecurrenceFreq { daily, weekly, monthly, yearly, dates }

enum RecurrenceMonthlyMode {
  day,

  weekday,
}

@immutable
class RecurrenceMonthly {
  const RecurrenceMonthly({
    this.mode = RecurrenceMonthlyMode.day,
    this.day,
    this.nth,
    this.weekday,
  });

  const RecurrenceMonthly.onDay(int this.day)
    : mode = RecurrenceMonthlyMode.day,
      nth = null,
      weekday = null;

  const RecurrenceMonthly.onWeekday({
    required int this.nth,
    required int this.weekday,
  }) : mode = RecurrenceMonthlyMode.weekday,
       day = null;

  static const lastDay = 31;

  static const lastWeek = -1;

  final RecurrenceMonthlyMode mode;
  final int? day;
  final int? nth;
  final int? weekday;

  @override
  bool operator ==(Object other) =>
      other is RecurrenceMonthly &&
      other.mode == mode &&
      other.day == day &&
      other.nth == nth &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(mode, day, nth, weekday);

  @override
  String toString() =>
      'RecurrenceMonthly($mode, day: $day, nth: $nth, weekday: $weekday)';
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
    this.dates = const [],
    this.end = const RecurrenceEnd.never(),
  });

  final RecurrenceFreq freq;
  final int interval;
  final Set<int> weekdays;
  final RecurrenceMonthly? monthly;
  final List<DateTime> dates;
  final DateTime start;
  final RecurrenceEnd end;

  RecurrenceRule copyWith({
    RecurrenceFreq? freq,
    int? interval,
    Set<int>? weekdays,
    RecurrenceMonthly? monthly,
    bool clearMonthly = false,
    List<DateTime>? dates,
    DateTime? start,
    RecurrenceEnd? end,
  }) => RecurrenceRule(
    freq: freq ?? this.freq,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    monthly: clearMonthly ? null : (monthly ?? this.monthly),
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
      listEquals(other.dates, dates) &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(
    freq,
    interval,
    Object.hashAllUnordered(weekdays),
    monthly,
    Object.hashAll(dates),
    start,
    end,
  );

  @override
  String toString() =>
      'RecurrenceRule($freq, interval: $interval, weekdays: $weekdays, '
      'monthly: $monthly, dates: $dates, start: $start, end: $end)';
}
