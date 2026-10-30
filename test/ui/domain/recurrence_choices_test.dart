import 'package:chubi_pocket/ui/domain/recurring/recurrence_choices.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the repeat sheet's chips turn into. Start = Tue 13 Oct 2026 (the 2nd
/// Tuesday); 31 Oct 2026 is the 5th Saturday.
void main() {
  final start = DateTime(2026, 10, 13);

  RecurrenceChoices of(
    RecurrenceFreq freq, {
    DateTime? at,
    bool simple = false,
  }) => RecurrenceChoices(
    RecurrenceRule(freq: freq, start: at ?? start),
    simple: simple,
  );

  test('weekly: toggles edit the set, the last one on stays', () {
    final c = RecurrenceChoices(
      RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        start: start,
        weekdays: const {1},
      ),
      simple: false,
    );
    c.toggleWeekday(3);
    expect(c.toggleWeekday(5)!.weekdays, {1, 3, 5});

    final empty = of(RecurrenceFreq.weekly);
    expect(empty.weekdays, {2}, reason: 'empty = the start weekday');
    empty.toggleWeekday(4);
    empty.toggleWeekday(2);
    expect(empty.toggleWeekday(4), isNull);
    expect(empty.build().weekdays, {4});
  });

  test('monthly: by day, and the weekday mode gives the Nth weekday', () {
    for (final x in [
      (
        name: '13th = 2nd Tuesday',
        at: start,
        day: const RecurrenceMonthly.onDay(13),
        weekday: const RecurrenceMonthly.onWeekday(nth: 2, weekday: 2),
      ),
      (
        name: '31st = last day; the 5th week = last',
        at: DateTime(2026, 10, 31),
        day: const RecurrenceMonthly.onDay(RecurrenceMonthly.lastDay),
        weekday: const RecurrenceMonthly.onWeekday(
          nth: RecurrenceMonthly.lastWeek,
          weekday: 6,
        ),
      ),
    ]) {
      final c = of(RecurrenceFreq.monthly, at: x.at);
      expect(c.build().monthly, x.day, reason: x.name);
      final r = c.edit(() => c.monthlyMode = RecurrenceMonthlyMode.weekday);
      expect(r.monthly, x.weekday, reason: x.name);
    }
  });

  test('ends after N occurrences; hand-picked dates start monthly', () {
    final c = of(RecurrenceFreq.monthly);
    expect(
      c.edit(() {
        c.endKind = RecurrenceEndKind.afterCount;
        c.endCount = 24;
      }).end,
      const RecurrenceEnd.afterCount(24),
    );

    final dates = RecurrenceChoices(
      RecurrenceRule(
        freq: RecurrenceFreq.dates,
        start: start,
        dates: [DateTime(2026, 10, 20), DateTime(2026, 11, 3)],
      ),
      simple: false,
    );
    expect(dates.freq, RecurrenceFreq.monthly);
    expect(dates.monthDay, 13);
    final r = dates.edit(() {
      dates.interval = 3;
      dates.freq = RecurrenceFreq.yearly;
      dates.endKind = RecurrenceEndKind.never;
    });
    expect(
      r,
      RecurrenceRule(freq: RecurrenceFreq.yearly, start: start, interval: 3),
    );
  });

  test('simple (budget periods): the start moves to the picked weekday', () {
    final c = of(RecurrenceFreq.weekly, simple: true);
    final r = c.edit(() => c.startWeekday = DateTime.thursday);
    expect(r.start, DateTime(2026, 10, 15));
    expect(r.weekdays, isEmpty);
  });
}
