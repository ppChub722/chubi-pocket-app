import 'package:flutter/foundation.dart';

/// How often a [RecurrenceRule] repeats.
///
/// [dates] = hand-picked dates ("กำหนดเอง"): the rule is just
/// [RecurrenceRule.dates], [RecurrenceRule.interval] is ignored.
enum RecurrenceFreq { daily, weekly, monthly, yearly, dates }

/// Which day of the month a monthly rule lands on.
enum RecurrenceMonthlyMode {
  /// A day number ([RecurrenceMonthly.day]; 31 = the last day).
  day,

  /// The Nth weekday ([RecurrenceMonthly.nth] + [RecurrenceMonthly.weekday]).
  weekday,
}

/// The monthly part of a [RecurrenceRule] (Google Calendar's "Monthly on
/// day 3" vs "Monthly on the second Monday").
///
/// - [RecurrenceMonthlyMode.day]: [day] 1..31, 31 = the last day of the
///   month (any month length). Null = the start date's day.
/// - [RecurrenceMonthlyMode.weekday]: [nth] 1..5 or -1 = the last one, and
///   [weekday] ISO 1 = Monday .. 7 = Sunday. Null = from the start date.
@immutable
class RecurrenceMonthly {
  const RecurrenceMonthly({
    this.mode = RecurrenceMonthlyMode.day,
    this.day,
    this.nth,
    this.weekday,
  });

  /// "Every month on day [day]" (31 = last day).
  const RecurrenceMonthly.onDay(int this.day)
    : mode = RecurrenceMonthlyMode.day,
      nth = null,
      weekday = null;

  /// "Every month on the [nth] [weekday]" ([nth] -1 = the last one).
  const RecurrenceMonthly.onWeekday({
    required int this.nth,
    required int this.weekday,
  }) : mode = RecurrenceMonthlyMode.weekday,
       day = null;

  /// The day number meaning "the last day of the month".
  static const lastDay = 31;

  /// The [nth] meaning "the last such weekday of the month".
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

/// When a [RecurrenceRule] stops: [RecurrenceEnd.never],
/// [RecurrenceEnd.onDate] (last possible date, inclusive) or
/// [RecurrenceEnd.afterCount] (that many occurrences in total).
///
/// A plain value class with a [kind]: switch on [kind], read [date] /
/// [count] for the matching kind (null otherwise).
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

  /// Set for [RecurrenceEndKind.onDate] (date only; the time is ignored).
  final DateTime? date;

  /// Set for [RecurrenceEndKind.afterCount].
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

/// The kind of a [RecurrenceEnd].
enum RecurrenceEndKind { never, onDate, afterCount }

/// A recurrence rule (Google Calendar style) — the generator part of a
/// recurring item. Plain data: the recurring feature maps the API JSON into
/// it, the "custom repeat" sheet returns it, [RecurrenceText] /
/// `recurrenceLabel` render it. Value equality, so a sheet can tell whether
/// anything changed.
///
/// - [freq] + [interval]: every [interval] days / weeks / months / years
///   (ignored for [RecurrenceFreq.dates]).
/// - [weekdays] (weekly): ISO 1 = Monday .. 7 = Sunday; empty = the
///   [start] date's weekday.
/// - [monthly] (monthly): see [RecurrenceMonthly]; null = the [start]
///   date's day number.
/// - yearly: the month + day of [start].
/// - [dates] ([RecurrenceFreq.dates]): the hand-picked dates.
/// - [start]: the first possible date; [end]: when it stops.
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
