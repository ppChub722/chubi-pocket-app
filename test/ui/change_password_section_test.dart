import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _strings = ChangePasswordStrings(
  title: 'Change password',
  primaryLabel: 'Do it',
  currentLabel: 'Current',
  newLabel: 'New',
  newHelper: 'At least 8',
  confirmLabel: 'Confirm',
  requiredError: 'Required',
  tooShort: 'Too short',
  tooLong: 'Too long',
  mustDiffer: 'Must differ',
  mismatch: 'Mismatch',
  success: 'Updated',
);

/// Change password = a collapsible section of the profile page whose fields are
/// the same kit piece as a detail page's note in edit.
void main() {
  Future<void> pump(
    WidgetTester t,
    Future<ChangePasswordFailure?> Function(String, String) onSubmit,
  ) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => AppUiConfig(child: child!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ChangePasswordSection(strings: _strings, onSubmit: onSubmit),
        ),
      ),
    ),
  );

  Future<void> fill(WidgetTester t, String c, String n, String f) async {
    final fields = find.byType(EditableText);
    await t.enterText(fields.at(0), c);
    await t.enterText(fields.at(1), n);
    await t.enterText(fields.at(2), f);
    await t.pump();
  }

  testWidgets('closed by default; tapping the heading opens it', (t) async {
    await pump(t, (_, _) async => null);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.byType(DetailTextField), findsNothing);
    await t.tap(find.text('Change password'));
    await t.pumpAndSettle();
    expect(find.byType(DetailTextField), findsNWidgets(3));
    expect(find.text('At least 8'), findsOneWidget);
  });

  testWidgets('fields are the note field piece, stacked + obscured', (t) async {
    await pump(t, (_, _) async => null);
    await t.tap(find.text('Change password'));
    await t.pumpAndSettle();
    final fields = t.widgetList<DetailTextField>(find.byType(DetailTextField));
    expect(fields.every((f) => f.obscurable && f.editing), isTrue);
    expect(find.byType(DetailStacked), findsNWidgets(3));
  });

  testWidgets('mismatch is a field error and sends nothing', (t) async {
    var calls = 0;
    await pump(t, (_, _) async {
      calls++;
      return null;
    });
    await t.tap(find.text('Change password'));
    await t.pumpAndSettle();
    await fill(t, 'oldpass123', 'newpass123', 'different1');
    await t.tap(find.text('Do it'));
    await t.pumpAndSettle();
    expect(find.text('Mismatch'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('wrong current = field error; success clears + collapses', (
    t,
  ) async {
    await pump(t, (cur, _) async {
      return cur == 'wrongpass1'
          ? const ChangePasswordFailure(currentError: 'Wrong')
          : null;
    });
    await t.tap(find.text('Change password'));
    await t.pumpAndSettle();
    await fill(t, 'wrongpass1', 'newpass123', 'newpass123');
    await t.tap(find.text('Do it'));
    await t.pumpAndSettle();
    expect(find.text('Wrong'), findsOneWidget);
    expect(find.byType(DetailTextField), findsNWidgets(3));

    await t.enterText(find.byType(EditableText).at(0), 'rightpass1');
    await t.tap(find.text('Do it'));
    await t.pumpAndSettle();
    // Collapsed again, fields cleared (a re-open shows empty ones).
    expect(find.byType(DetailTextField), findsNothing);
    await t.tap(find.text('Change password'));
    await t.pumpAndSettle();
    expect(find.text('rightpass1'), findsNothing);
  });
}
