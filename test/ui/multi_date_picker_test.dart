import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// K4 — the multi-date picker: toggle, bounds, chips, confirm label + result.
void main() {
  Set<DateTime>? confirmed;
  Set<DateTime>? changed;

  Future<void> pump(
    WidgetTester tester, {
    Set<DateTime> initial = const {},
    DateTime? first,
    DateTime? last,
  }) async {
    confirmed = null;
    changed = null;
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: MultiDatePickerSheet(
            initial: initial,
            first: first ?? DateTime(2026, 10, 5),
            last: last ?? DateTime(2026, 10, 25),
            title: 'Pick the dates',
            confirmLabel: (n) => 'Use $n dates',
            onChanged: (s) => changed = s,
            onConfirm: (s) => confirmed = s,
          ),
        ),
      ),
    );
  }

  /// A day cell of the calendar (not a chip label).
  Finder day(String n) =>
      find.descendant(of: find.byType(InkResponse), matching: find.text(n));

  AppButton confirmButton(WidgetTester tester) => tester.widget<AppButton>(
    find.byWidgetPredicate((w) => w is AppButton && w.label.startsWith('Use ')),
  );

  testWidgets('tapping days toggles them; the confirm counts them', (
    tester,
  ) async {
    await pump(tester, initial: {DateTime(2026, 10, 10)});
    expect(find.text('Use 1 dates'), findsOneWidget);

    await tester.tap(day('12'));
    await tester.pump();
    expect(find.text('Use 2 dates'), findsOneWidget);
    expect(changed, {DateTime(2026, 10, 10), DateTime(2026, 10, 12)});

    // Tap again = unpick.
    await tester.tap(day('10'));
    await tester.pump();
    expect(find.text('Use 1 dates'), findsOneWidget);
    expect(changed, {DateTime(2026, 10, 12)});
  });

  testWidgets('days outside first / last ignore taps; initial outside drops', (
    tester,
  ) async {
    await pump(tester, initial: {DateTime(2026, 10, 1), DateTime(2026, 10, 6)});
    // Oct 1 is before `first` → dropped on open.
    expect(find.text('Use 1 dates'), findsOneWidget);

    await tester.tap(day('3'));
    await tester.tap(day('28'));
    await tester.pump();
    expect(find.text('Use 1 dates'), findsOneWidget);
    expect(changed, isNull);

    // The bounds are inside one month: no navigation either way.
    final arrows = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .toList();
    expect(arrows.every((b) => b.onPressed == null), isTrue);
  });

  testWidgets('picked days show as chips; tapping a chip removes it', (
    tester,
  ) async {
    await pump(
      tester,
      initial: {DateTime(2026, 10, 8), DateTime(2026, 10, 20)},
    );
    expect(find.byType(AppChip), findsNWidgets(2));

    await tester.tap(find.byType(AppChip).first);
    await tester.pump();
    expect(find.byType(AppChip), findsOneWidget);
    expect(changed, {DateTime(2026, 10, 20)});
    expect(find.text('Use 1 dates'), findsOneWidget);
  });

  testWidgets('clear empties; the confirm is off with nothing picked', (
    tester,
  ) async {
    await pump(tester, initial: {DateTime(2026, 10, 8)});
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(changed, isEmpty);
    expect(find.byType(AppChip), findsNothing);
    expect(find.text(const UiStrings().pickDatesHint), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('confirm returns the picked days normalised to y/m/d', (
    tester,
  ) async {
    await pump(
      tester,
      // A time part on the way in is dropped.
      initial: {DateTime(2026, 10, 9, 15, 30)},
      first: DateTime(2026, 10, 5, 23, 59),
      last: DateTime(2026, 11, 30),
    );
    await tester.tap(day('15'));
    await tester.pump();
    // Next month, pick the 2nd.
    await tester.tap(find.byTooltip(const UiStrings().monthNext));
    await tester.pump();
    await tester.tap(day('2'));
    await tester.pump();
    await tester.tap(find.text('Use 3 dates'));
    await tester.pump();
    expect(confirmed, {
      DateTime(2026, 10, 9),
      DateTime(2026, 10, 15),
      DateTime(2026, 11, 2),
    });
  });

  testWidgets('showMultiDatePicker resolves with the confirmed set', (
    tester,
  ) async {
    Set<DateTime>? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showMultiDatePicker(
                context,
                initial: {DateTime(2026, 10, 10)},
                first: DateTime(2026, 10, 1),
                last: DateTime(2026, 10, 31),
                title: 'Pick the dates',
                confirmLabel: (n) => 'Use $n dates',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Pick the dates'), findsOneWidget);
    await tester.tap(find.text('Use 1 dates'));
    await tester.pumpAndSettle();
    expect(result, {DateTime(2026, 10, 10)});
  });
}
