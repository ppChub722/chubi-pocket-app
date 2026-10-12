import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The custom repeat sheet: weekday toggles, the monthly mode, the end, and
/// what Cancel / OK resolve to. Start = Tue 13 Oct 2026 (the 2nd Tuesday).
void main() {
  final start = DateTime(2026, 10, 13);
  final th = lookupAppLocalizations(const Locale('th'));

  setUpAll(() async {
    await initializeDateFormatting('th');
    await initializeDateFormatting('en');
  });

  /// Pumps a button that opens the sheet with [initial]; returns a getter
  /// for (opened?, result).
  Future<(bool, RecurrenceRule?) Function()> open(
    WidgetTester t,
    RecurrenceRule initial,
  ) async {
    t.view.physicalSize = const Size(420, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var done = false;
    RecurrenceRule? result;
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Builder(
            builder: (context) => AppButton(
              label: 'open',
              onPressed: () async {
                result = await showRecurrenceSheet(context, initial: initial);
                done = true;
              },
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return () => (done, result);
  }

  Future<void> tapText(WidgetTester t, String text) async {
    await t.tap(find.text(text));
    await t.pumpAndSettle();
  }

  Finder weekday(int iso) => find.byKey(ValueKey('recurWeekday$iso'));

  testWidgets('weekly: toggling weekdays edits the set, one always stays', (
    t,
  ) async {
    final state = await open(
      t,
      RecurrenceRule(
        freq: RecurrenceFreq.weekly,
        start: start,
        weekdays: const {1},
      ),
    );
    expect(find.text(th.recurSheetTitle), findsOneWidget);
    // Wed + Fri on.
    await t.tap(weekday(3));
    await t.pump();
    await t.tap(weekday(5));
    await t.pump();
    // The live summary follows.
    expect(find.text('ทุกวันจันทร์ พุธ และศุกร์'), findsOneWidget);
    await tapText(t, th.commonOk);
    final (done, r) = state();
    expect(done, isTrue);
    expect(r!.freq, RecurrenceFreq.weekly);
    expect(r.weekdays, {1, 3, 5});
  });

  testWidgets('weekly: the last weekday on cannot be turned off', (t) async {
    final state = await open(
      t,
      RecurrenceRule(freq: RecurrenceFreq.weekly, start: start),
    );
    // Empty weekdays = the start's (Tuesday), shown on: Thu on, Tue off,
    // then Thu (the last one on) stays.
    expect(find.text('ทุกวันอังคาร'), findsOneWidget);
    for (final d in [4, 2, 4]) {
      await t.tap(weekday(d));
      await t.pump();
    }
    expect(find.text('ทุกวันพฤหัสบดี'), findsOneWidget);
    await tapText(t, th.commonOk);
    expect(state().$2!.weekdays, {4});
  });

  testWidgets('monthly: switching to the weekday mode gives the Nth weekday', (
    t,
  ) async {
    final state = await open(
      t,
      RecurrenceRule(freq: RecurrenceFreq.monthly, start: start),
    );
    expect(find.text(th.recurOnDay(13)), findsOneWidget);
    final nthLabel = th.recurOnNthWeekday('second', 2, th.recurWeekday2);
    await tapText(t, nthLabel);
    expect(find.text('ทุกวันอังคารที่ 2 ของเดือน'), findsOneWidget);
    await tapText(t, th.commonOk);
    expect(
      state().$2!.monthly,
      const RecurrenceMonthly.onWeekday(nth: 2, weekday: 2),
    );
  });

  testWidgets('monthly: day 31 reads as the last day; the 5th week = last', (
    t,
  ) async {
    await open(
      t,
      RecurrenceRule(
        freq: RecurrenceFreq.monthly,
        start: DateTime(2026, 10, 31),
      ),
    );
    expect(find.text(th.recurSheetLastDayOfMonth), findsOneWidget);
    // 31 Oct 2026 is the 5th Saturday → "the last Saturday".
    expect(find.text(th.recurOnLastWeekday(th.recurWeekday6)), findsOneWidget);
  });

  testWidgets('ends after N occurrences', (t) async {
    final state = await open(
      t,
      RecurrenceRule(freq: RecurrenceFreq.monthly, start: start),
    );
    await tapText(t, th.recurSheetEndAfter);
    // The interval field, then the count field.
    final count = find.byType(EditableText).at(1);
    await t.enterText(count, '24');
    await t.pump();
    await tapText(t, th.commonOk);
    expect(state().$2!.end, const RecurrenceEnd.afterCount(24));
  });

  testWidgets('Cancel resolves null', (t) async {
    final state = await open(
      t,
      RecurrenceRule(freq: RecurrenceFreq.daily, start: start),
    );
    await tapText(t, th.recurSheetUnitWeek(1));
    expect(weekday(2), findsOneWidget);
    await tapText(t, 'Cancel');
    final (done, r) = state();
    expect(done, isTrue);
    expect(r, isNull);
  });

  testWidgets('OK returns the edited rule; hand-picked dates start monthly', (
    t,
  ) async {
    final state = await open(
      t,
      RecurrenceRule(
        freq: RecurrenceFreq.dates,
        start: start,
        dates: [DateTime(2026, 10, 20), DateTime(2026, 11, 3)],
      ),
    );
    // Starts as monthly on the start's day.
    expect(find.text(th.recurMonthlyOnDay(13)), findsOneWidget);
    await t.enterText(find.byType(EditableText).first, '3');
    await t.pump();
    await tapText(t, th.recurSheetUnitYear(3));
    await tapText(t, th.recurSheetEndNever);
    await tapText(t, th.commonOk);
    expect(
      state().$2,
      RecurrenceRule(freq: RecurrenceFreq.yearly, start: start, interval: 3),
    );
  });
}
