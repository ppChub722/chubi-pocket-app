import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/features/tags/presentation/widgets/tag_picker_sheet.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stacked sheets (owner bug 2026-10-10): the "+ แท็กใหม่" name sheet used to
/// dispose its text controller as soon as the sheet's future resolved —
/// while the sheet was still animating out with the field on screen.
void main() {
  testWidgets('the new-tag name sheet closes without using a disposed '
      'controller', (t) async {
    String? result;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('th'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => result = await askNewTagName(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'งาน');
    await t.tap(find.text('บันทึก'));
    // Run the exit animation frame by frame.
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(result, 'งาน');
  });
}
