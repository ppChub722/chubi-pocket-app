import 'package:chubi_pocket/hub/pages/domain_recurring_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  group('dueLabel', () {
    String thDue(DateTime d, {bool withDate = false, int? daysUntil}) =>
        dueLabel(
          th,
          date: d,
          daysUntil: daysUntil,
          withDate: withDate,
          today: today,
        );

    test('TH relative wording, computed from today', () {
      expect(thDue(DateTime(2026, 10, 13)), 'วันนี้');
      expect(thDue(DateTime(2026, 10, 14)), 'พรุ่งนี้');
      expect(thDue(DateTime(2026, 10, 12)), 'เมื่อวาน');
      expect(thDue(DateTime(2026, 10, 16)), 'อีก 3 วัน');
      expect(thDue(DateTime(2026, 10, 11)), 'เลยกำหนด 2 วัน');
      // Across a month / year boundary.
      expect(thDue(DateTime(2026, 11, 3)), 'อีก 21 วัน');
    });

    test('daysUntil from the BE wins over the computed distance', () {
      expect(thDue(DateTime(2026, 10, 13), daysUntil: 5), 'อีก 5 วัน');
    });

    test('with the short date (year only when not this year)', () {
      expect(
        thDue(DateTime(2026, 11, 3), withDate: true),
        'อีก 21 วัน | 3 พ.ย.',
      );
      expect(
        thDue(DateTime(2027, 1, 2), withDate: true),
        startsWith('อีก 81 วัน | 2 ม.ค.'),
      );
    });

    test('EN wording + plurals', () {
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
  });

  group('recurrenceLabel', () {
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

    test('TH every frequency', () {
      String t(RecurrenceRule x) => recurrenceLabel(th, x);
      expect(t(r(RecurrenceFreq.daily)), 'ทุกวัน');
      expect(t(r(RecurrenceFreq.daily, interval: 2)), 'ทุก 2 วัน');
      expect(t(r(RecurrenceFreq.weekly, weekdays: {1})), 'ทุกวันจันทร์');
      expect(t(r(RecurrenceFreq.weekly)), 'ทุกวันเสาร์'); // start's weekday
      expect(
        t(r(RecurrenceFreq.weekly, weekdays: {3, 1})),
        'ทุกวันจันทร์และพุธ',
      );
      expect(
        t(r(RecurrenceFreq.weekly, weekdays: {1, 3, 5})),
        'ทุกวันจันทร์ พุธ และศุกร์',
      );
      expect(
        t(r(RecurrenceFreq.weekly, interval: 2, weekdays: {1})),
        'ทุก 2 สัปดาห์ | วันจันทร์',
      );
      expect(t(r(RecurrenceFreq.monthly)), 'ทุกวันที่ 3');
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onDay(RecurrenceMonthly.lastDay),
          ),
        ),
        'ทุกวันสุดท้ายของเดือน',
      );
      expect(
        t(r(RecurrenceFreq.monthly, interval: 3)),
        'ทุก 3 เดือน | วันที่ 3',
      );
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(nth: 2, weekday: 1),
          ),
        ),
        'ทุกวันจันทร์ที่ 2 ของเดือน',
      );
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(
              nth: RecurrenceMonthly.lastWeek,
              weekday: 5,
            ),
          ),
        ),
        'ทุกวันศุกร์สุดท้ายของเดือน',
      );
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            interval: 2,
            monthly: const RecurrenceMonthly.onWeekday(nth: 2, weekday: 1),
          ),
        ),
        'ทุก 2 เดือน | วันจันทร์ที่ 2',
      );
      expect(t(r(RecurrenceFreq.yearly)), 'ทุกปี 3 ต.ค.');
      expect(t(r(RecurrenceFreq.yearly, interval: 2)), 'ทุก 2 ปี | 3 ต.ค.');
      expect(
        t(
          r(
            RecurrenceFreq.dates,
            dates: List.generate(5, (i) => DateTime(2026, 10, 3 + i)),
          ),
        ),
        'กำหนดเอง 5 วัน',
      );
      expect(t(r(RecurrenceFreq.dates)), 'กำหนดเอง');
    });

    test('TH progress + end suffix', () {
      final monthly = r(
        RecurrenceFreq.monthly,
        end: const RecurrenceEnd.afterCount(12),
      );
      expect(
        recurrenceLabel(th, monthly, seq: 4, total: 12),
        'ทุกวันที่ 3 | 4/12',
      );
      expect(
        recurrenceLabel(th, monthly, showEnd: true),
        'ทุกวันที่ 3 | 12 ครั้ง',
      );
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
      // never → no suffix; only seq (no total) → no progress.
      expect(
        recurrenceLabel(th, r(RecurrenceFreq.daily), showEnd: true, seq: 3),
        'ทุกวัน',
      );
    });

    test('EN every frequency', () {
      String t(RecurrenceRule x) => recurrenceLabel(en, x);
      expect(t(r(RecurrenceFreq.daily)), 'Every day');
      expect(t(r(RecurrenceFreq.daily, interval: 2)), 'Every 2 days');
      expect(t(r(RecurrenceFreq.weekly, weekdays: {1})), 'Every Monday');
      expect(
        t(r(RecurrenceFreq.weekly, weekdays: {1, 3, 5})),
        'Every Monday, Wednesday and Friday',
      );
      expect(
        t(r(RecurrenceFreq.weekly, interval: 2, weekdays: {1, 3})),
        'Every 2 weeks | Monday and Wednesday',
      );
      expect(t(r(RecurrenceFreq.monthly)), 'Monthly on day 3');
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(nth: 2, weekday: 1),
          ),
        ),
        'Monthly on the second Monday',
      );
      expect(
        t(
          r(
            RecurrenceFreq.monthly,
            monthly: const RecurrenceMonthly.onWeekday(nth: -1, weekday: 5),
          ),
        ),
        'Monthly on the last Friday',
      );
      expect(t(r(RecurrenceFreq.yearly)), 'Every year on Oct 3');
      expect(
        t(r(RecurrenceFreq.dates, dates: [start, start])),
        'Custom | 2 dates',
      );
      expect(
        recurrenceLabel(
          en,
          r(RecurrenceFreq.monthly, end: const RecurrenceEnd.afterCount(12)),
          showEnd: true,
          seq: 4,
          total: 12,
        ),
        'Monthly on day 3 | 12 times | 4/12',
      );
    });
  });

  group('RecurrenceRule value equality', () {
    test('== / hashCode by value (weekday order does not matter)', () {
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
  });

  group('widgets', () {
    Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: [
            ThemeRegistry.byId(
              ThemeRegistry.defaultThemeId,
            ).colorsFor(Brightness.light),
          ],
        ),
        home: Scaffold(body: Center(child: child)),
      ),
    );

    testWidgets('DueText tints overdue danger, not upcoming', (t) async {
      await pump(
        t,
        Column(
          children: [
            DueText(date: DateTime(2026, 10, 11), today: today),
            DueText(date: DateTime(2026, 10, 16), today: today),
            DueText(
              date: DateTime(2026, 10, 11),
              today: today,
              tintOverdue: false,
            ),
          ],
        ),
      );
      final ctx = t.element(find.byType(Column).first);
      final danger = Tone.danger.color(ctx);
      Color? colorOf(String prefix) =>
          t.widget<Text>(find.textContaining(prefix).first).style?.color;
      final texts = t.widgetList<Text>(find.byType(Text)).toList();
      expect(texts[0].data, 'เลยกำหนด 2 วัน | 11 ต.ค.');
      expect(texts[0].style?.color, danger);
      expect(colorOf('อีก 3 วัน'), isNot(danger));
      expect(texts[2].style?.color, isNot(danger));
    });

    testWidgets('RecurrenceText renders the label with progress', (t) async {
      await pump(
        t,
        RecurrenceText(
          rule: RecurrenceRule(
            freq: RecurrenceFreq.monthly,
            start: DateTime(2026, 10, 3),
          ),
          seq: 4,
          total: 12,
        ),
      );
      expect(find.text('ทุกวันที่ 3 | 4/12'), findsOneWidget);
    });

    testWidgets('hub page builds, playground opens, no layout errors', (
      t,
    ) async {
      t.view.physicalSize = const Size(420 * 3, 4000 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = previous);
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              ThemeRegistry.byId(
                ThemeRegistry.defaultThemeId,
              ).colorsFor(Brightness.light),
            ],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('th'),
          builder: (context, child) => AppUiConfig(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: buildRecurringPage(context),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      const title = 'Customize | RecurrenceText';
      await t.ensureVisible(find.text(title));
      await t.tap(find.text(title));
      await t.pumpAndSettle();
      expect(find.byType(DueText), findsNWidgets(12));
      // 14 + 5 demos + the playground's live instance.
      expect(find.byType(RecurrenceText), findsNWidgets(20));
      t.takeException();
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  });
}
