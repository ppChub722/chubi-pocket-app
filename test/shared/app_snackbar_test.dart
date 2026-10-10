import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// QA run-3 S1: a message raised inside a sheet must show ABOVE the sheet
/// (a snackbar landed on the page under it — invisible).
void main() {
  Future<BuildContext> openSheet(WidgetTester t) async {
    late BuildContext sheetContext;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (ctx) {
                  sheetContext = ctx;
                  return const SizedBox(height: 300, child: Text('sheet'));
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return sheetContext;
  }

  testWidgets('from a sheet: a toast over the sheet, not a snackbar', (
    t,
  ) async {
    final ctx = await openSheet(t);
    showAppSnackBar(ctx, 'ยอดที่แบ่งยังไม่ลงตัว', tone: Tone.danger);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsNothing);
    // On top: hit-testable over the sheet's barrier.
    expect(find.text('ยอดที่แบ่งยังไม่ลงตัว').hitTestable(), findsOneWidget);

    // Gone after a few seconds.
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(find.text('ยอดที่แบ่งยังไม่ลงตัว'), findsNothing);
  });

  testWidgets('a new one replaces the one showing', (t) async {
    final ctx = await openSheet(t);
    showAppSnackBar(ctx, 'หนึ่ง');
    await t.pump();
    showAppSnackBar(ctx, 'สอง');
    await t.pump();
    expect(find.text('หนึ่ง'), findsNothing);
    expect(find.text('สอง'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
  });

  testWidgets('from a page: the usual snackbar', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSnackBar(context, 'บันทึกแล้ว'),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pump();
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
