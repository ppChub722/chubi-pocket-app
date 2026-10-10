import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<DateTime> picked;

  Future<void> pump(WidgetTester t, DateTime month, {DateTime? last}) async {
    picked = [];
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: MonthPill(month: month, last: last, onChanged: picked.add),
          ),
        ),
      ),
    );
  }

  testWidgets('‹ › step a month; › stops at the last month', (t) async {
    await pump(t, DateTime(2026, 3), last: DateTime(2026, 3, 20));
    await t.tap(find.byTooltip('Next month'));
    expect(picked, isEmpty);
    await t.tap(find.byTooltip('Previous month'));
    expect(picked, [DateTime(2026, 2)]);
  });

  testWidgets('the label opens the grid: selected shown, future disabled', (
    t,
  ) async {
    await pump(t, DateTime(2026, 3), last: DateTime(2026, 3));
    await t.tap(find.text('March 2026'));
    await t.pumpAndSettle();
    expect(find.text('Pick a month'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    // April is past the last month — nothing happens.
    await t.tap(find.text('Apr'));
    await t.pumpAndSettle();
    expect(picked, isEmpty);
    // Next year is all future — its arrow is off.
    final nextYear = t.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(nextYear.onPressed, isNull);
    // Back a year, pick a month → the sheet closes with it.
    await t.tap(find.byTooltip('Previous year'));
    await t.pumpAndSettle();
    await t.tap(find.text('Nov'));
    await t.pumpAndSettle();
    expect(picked, [DateTime(2025, 11)]);
    expect(find.text('Pick a month'), findsNothing);
  });

  testWidgets('"This month" jumps to the current month', (t) async {
    final now = DateTime.now();
    await pump(t, DateTime(now.year - 1, 1));
    await t.tap(find.textContaining('January'));
    await t.pumpAndSettle();
    await t.tap(find.text('This month'));
    await t.pumpAndSettle();
    expect(picked, [DateTime(now.year, now.month)]);
  });
}
