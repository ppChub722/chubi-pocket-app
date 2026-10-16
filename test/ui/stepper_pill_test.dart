import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// StepperPill presets (owner 2026-10-12: MonthPill + the budgets' period
/// navigator are StepperPill presets, not widgets of their own).
void main() {
  test('startOf / shift: week starts Monday, month and year roll over', () {
    // 2026-10-14 is a Wednesday.
    expect(
      StepperPill.startOf(StepperUnit.week, DateTime(2026, 10, 14)),
      DateTime(2026, 10, 12),
    );
    expect(
      StepperPill.shift(StepperUnit.week, DateTime(2026, 12, 28), 1),
      DateTime(2027, 1, 4),
    );
    expect(
      StepperPill.shift(StepperUnit.month, DateTime(2026, 1), -1),
      DateTime(2025, 12),
    );
    expect(
      StepperPill.shift(StepperUnit.year, DateTime(2026), 1),
      DateTime(2027),
    );
  });

  Future<void> pump(WidgetTester t, Widget pill) => t.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: pill)),
    ),
  );

  testWidgets('week preset steps by a week and stops at last', (t) async {
    final got = <DateTime>[];
    await pump(
      t,
      StepperPill.period(
        unit: StepperUnit.week,
        value: DateTime(2026, 10, 14),
        last: DateTime(2026, 10, 14),
        onChanged: got.add,
      ),
    );
    await t.tap(find.byIcon(PpForgeIcons.chevronLeft));
    expect(got, [DateTime(2026, 10, 5)]);
    // › is dimmed and does nothing at the last period.
    await t.tap(find.byIcon(PpForgeIcons.chevronRight));
    expect(got.length, 1);
  });

  testWidgets('year preset: no picker, no ▾; month preset: ▾', (t) async {
    await pump(
      t,
      StepperPill.period(
        unit: StepperUnit.year,
        value: DateTime(2026, 5),
        onChanged: (_) {},
      ),
    );
    expect(find.byIcon(PpForgeIcons.dropdown), findsNothing);
    await pump(
      t,
      StepperPill.month(value: DateTime(2026, 5), onChanged: (_) {}),
    );
    expect(find.byIcon(PpForgeIcons.dropdown), findsOneWidget);
  });
}
