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

  test('monthly: several days and สิ้นเดือน (spec §3.1), the last one stays; '
      'a kept Nth weekday gives way to a picked day', () {
    final c = of(RecurrenceFreq.monthly);
    expect(c.build().monthDays, {13}, reason: 'empty = the start day');
    c.toggleMonthDay(20);
    final r = c.toggleMonthDay(RecurrenceRule.lastDay)!;
    expect(r.monthDays, {13, 20, RecurrenceRule.lastDay});
    expect(r.monthly, isNull);
    c.toggleMonthDay(13);
    c.toggleMonthDay(20);
    expect(c.toggleMonthDay(RecurrenceRule.lastDay), isNull);

    // "4th Wednesday" stays in the model (not on screen) until a day is picked
    final nth = RecurrenceChoices(
      RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: start,
        monthly: const RecurrenceMonthly.onWeekday(nth: 2, weekday: 2),
      ),
      simple: false,
    );
    expect(nth.build().monthly?.nth, 2);
    final picked = nth.toggleMonthDay(5)!;
    expect(picked.monthly, isNull);
    expect(picked.monthDays, {5});
  });

  test('yearly: months on top, then days', () {
    final c = of(RecurrenceFreq.yearly);
    expect(c.build().months, {10});
    final r = c.toggleMonth(4)!;
    expect(r.months, {4, 10});
    expect(c.toggleMonth(4)!.months, {10});
    expect(c.toggleMonth(10), isNull, reason: 'the last one left stays');
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
      dates.pickDates = false;
      dates.interval = 3;
      dates.freq = RecurrenceFreq.yearly;
      dates.endKind = RecurrenceEndKind.never;
    });
    expect(
      r,
      // repeat mode keeps the month and day it shows (spec §3.1)
      RecurrenceRule(
        freq: RecurrenceFreq.yearly,
        start: start,
        interval: 3,
        monthDays: const {13},
        months: const {10},
      ),
    );
  });

  test('simple (budget periods): the start moves to the picked weekday', () {
    final c = of(RecurrenceFreq.weekly, simple: true);
    final r = c.edit(() => c.startWeekday = DateTime.thursday);
    expect(r.start, DateTime(2026, 10, 15));
    expect(r.weekdays, isEmpty);
  });
}
