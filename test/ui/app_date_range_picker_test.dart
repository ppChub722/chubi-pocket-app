import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('range picker: tap start, tap end, Save returns the range', (
    tester,
  ) async {
    DateTimeRange? got;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: AppDateRangePickerSheet(
            initial: DateTimeRange(
              start: DateTime(2026, 10, 1),
              end: DateTime(2026, 10, 1),
            ),
            first: DateTime(2026, 1, 1),
            last: DateTime(2026, 12, 31),
            onResult: (r) => got = r,
          ),
        ),
      ),
    );
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.byType(AppButton));
    expect(got?.start, DateTime(2026, 10, 10));
    expect(got?.end, DateTime(2026, 10, 20));
  });
}
