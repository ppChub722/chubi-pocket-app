import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final th = lookupAppLocalizations(const Locale('th'));
  final en = lookupAppLocalizations(const Locale('en'));
  final today = DateTime(2026, 10, 13);

  setUpAll(() async {
    await initializeDateFormatting('th');
    await initializeDateFormatting('en');
  });

  String thDue(DateTime d, {bool withDate = false, int? daysUntil}) => dueLabel(
    th,
    date: d,
    daysUntil: daysUntil,
    withDate: withDate,
    today: today,
  );

  test('dueLabel: TH / EN wording from today, with the short date', () {
    expect(thDue(DateTime(2026, 10, 13)), 'วันนี้');
    expect(thDue(DateTime(2026, 10, 14)), 'พรุ่งนี้');
    expect(thDue(DateTime(2026, 10, 12)), 'เมื่อวาน');
    expect(thDue(DateTime(2026, 10, 16)), 'อีก 3 วัน');
    expect(thDue(DateTime(2026, 10, 11)), 'เลยกำหนด 2 วัน');
    expect(thDue(DateTime(2026, 11, 3)), 'อีก 21 วัน');
    expect(thDue(DateTime(2026, 11, 3), withDate: true), 'อีก 21 วัน | 3 พ.ย.');
    expect(
      thDue(DateTime(2027, 1, 2), withDate: true),
      startsWith('อีก 81 วัน | 2 ม.ค.'),
    );

    String d(DateTime x) =>
        dueLabel(en, date: x, withDate: false, today: today);
    expect(d(DateTime(2026, 10, 13)), 'Today');
    expect(d(DateTime(2026, 10, 14)), 'Tomorrow');
    expect(d(DateTime(2026, 10, 12)), 'Yesterday');
    expect(d(DateTime(2026, 10, 16)), 'in 3 days');
    expect(d(DateTime(2026, 10, 11)), '2 days overdue');
    expect(
      dueLabel(en, date: DateTime(2026, 11, 3), today: today),
      'in 21 days | Nov 3',
    );
  });

  test('daysUntil from the BE wins over the computed distance', () {
    expect(thDue(DateTime(2026, 10, 13), daysUntil: 5), 'อีก 5 วัน');
  });

  test('recurrenceLabel: every frequency, progress and end suffix', () {
    final start = DateTime(2026, 10, 3); // a Saturday
    RecurrenceRule r(
      RecurrenceFreq f, {
      int interval = 1,
      Set<int> weekdays = const {},
      RecurrenceMonthly? monthly,
      List<DateTime> dates = const [],
      RecurrenceEnd end = const RecurrenceEnd.never(),
    }) => RecurrenceRule(
      freq: f,
      start: start,
      interval: interval,
      weekdays: weekdays,
      monthly: monthly,
      dates: dates,
      end: end,
    );
    String t(RecurrenceRule x) => recurrenceLabel(th, x);
    String e(RecurrenceRule x) => recurrenceLabel(en, x);
    const secondMonday = RecurrenceMonthly.onWeekday(nth: 2, weekday: 1);
    final monthlyEnds12 = r(
      RecurrenceFreq.monthly,
      end: const RecurrenceEnd.afterCount(12),
    );

    for (final c in [
      (want: 'ทุกวัน', got: t(r(RecurrenceFreq.daily))),
      (want: 'ทุก 2 วัน', got: t(r(RecurrenceFreq.daily, interval: 2))),
      (want: 'ทุกวันจันทร์', got: t(r(RecurrenceFreq.weekly, weekdays: {1}))),
      (want: 'ทุกวันเสาร์', got: t(r(RecurrenceFreq.weekly))),
      (
        want: 'ทุกวันจันทร์และพุธ',
        got: t(r(RecurrenceFreq.weekly, weekdays: {3, 1})),
      ),
      (
        want: 'ทุกวันจันทร์ พุธ และศุกร์',
        got: t(r(RecurrenceFreq.weekly, weekdays: {1, 3, 5})),
      ),
      (
        want: 'ทุก 2 สัปดาห์ | วันจันทร์',
        got: t(r(RecurrenceFreq.weekly, interval: 2, weekdays: {1})),
      ),
      (want: 'ทุกวันที่ 3', got: t(r(RecurrenceFreq.monthly))),
      (
        want: 'ทุกวันสุดท้ายของเดือน',
        got: t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onDay(RecurrenceMonthly.lastDay),
          ),
        ),
      ),
      (
        want: 'ทุก 3 เดือน | วันที่ 3',
        got: t(r(RecurrenceFreq.monthly, interval: 3)),
      ),
      (
        want: 'ทุกวันจันทร์ที่ 2 ของเดือน',
        got: t(r(RecurrenceFreq.monthly, monthly: secondMonday)),
      ),
      (
        want: 'ทุกวันศุกร์สุดท้ายของเดือน',
        got: t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(
              nth: RecurrenceMonthly.lastWeek,
              weekday: 5,
            ),
          ),
        ),
      ),
      (
        want: 'ทุก 2 เดือน | วันจันทร์ที่ 2',
        got: t(r(RecurrenceFreq.monthly, interval: 2, monthly: secondMonday)),
      ),
      (want: 'ทุกปี 3 ต.ค.', got: t(r(RecurrenceFreq.yearly))),
      (
        want: 'ทุก 2 ปี | 3 ต.ค.',
        got: t(r(RecurrenceFreq.yearly, interval: 2)),
      ),
      (
        want: 'กำหนดเอง 5 วัน',
        got: t(
          r(
            RecurrenceFreq.dates,
            dates: List.generate(5, (i) => DateTime(2026, 10, 3 + i)),
          ),
        ),
      ),
      (want: 'กำหนดเอง', got: t(r(RecurrenceFreq.dates))),
      (
        want: 'ทุกวันที่ 3 | 4/12',
        got: recurrenceLabel(th, monthlyEnds12, seq: 4, total: 12),
      ),
      (
        want: 'ทุกวันที่ 3 | 12 ครั้ง',
        got: recurrenceLabel(th, monthlyEnds12, showEnd: true),
      ),
      (
        want: 'ทุกวัน',
        got: recurrenceLabel(
          th,
          r(RecurrenceFreq.daily),
          showEnd: true,
          seq: 3,
        ),
      ),
      (want: 'Every day', got: e(r(RecurrenceFreq.daily))),
      (want: 'Every 2 days', got: e(r(RecurrenceFreq.daily, interval: 2))),
      (
        want: 'Every Monday, Wednesday and Friday',
        got: e(r(RecurrenceFreq.weekly, weekdays: {1, 3, 5})),
      ),
      (
        want: 'Every 2 weeks | Monday and Wednesday',
        got: e(r(RecurrenceFreq.weekly, interval: 2, weekdays: {1, 3})),
      ),
      (want: 'Monthly on day 3', got: e(r(RecurrenceFreq.monthly))),
      (
        want: 'Monthly on the second Monday',
        got: e(r(RecurrenceFreq.monthly, monthly: secondMonday)),
      ),
      (
        want: 'Monthly on the last Friday',
        got: e(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(nth: -1, weekday: 5),
          ),
        ),
      ),
      (want: 'Every year on Oct 3', got: e(r(RecurrenceFreq.yearly))),
      (
        want: 'Custom | 2 dates',
        got: e(r(RecurrenceFreq.dates, dates: [start, start])),
      ),
      (
        want: 'Monthly on day 3 | 12 times | 4/12',
        got: recurrenceLabel(
          en,
          monthlyEnds12,
          showEnd: true,
          seq: 4,
          total: 12,
        ),
      ),
    ]) {
      expect(c.got, c.want);
    }
    expect(
      recurrenceLabel(
        th,
        r(
          RecurrenceFreq.monthly,
          end: RecurrenceEnd.onDate(DateTime(2027, 10, 3)),
        ),
        showEnd: true,
      ),
      startsWith('ทุกวันที่ 3 | ถึง 3 ต.ค.'),
    );
  });

  test('RecurrenceRule == / hashCode by value (weekday order is free)', () {
    final a = RecurrenceRule(
      freq: RecurrenceFreq.weekly,
      start: DateTime(2026, 10, 3),
      weekdays: const {1, 3},
      end: RecurrenceEnd.onDate(DateTime(2027, 1, 1)),
    );
    final b = RecurrenceRule(
      freq: RecurrenceFreq.weekly,
      start: DateTime(2026, 10, 3),
      weekdays: const {3, 1},
      end: RecurrenceEnd.onDate(DateTime(2027, 1, 1)),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == a.copyWith(interval: 2), isFalse);
    expect(const RecurrenceMonthly.onDay(3), const RecurrenceMonthly(day: 3));
  });
}
