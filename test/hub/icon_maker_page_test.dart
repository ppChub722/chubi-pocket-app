import 'package:chubi_pocket/hub/pages/icons_icon_maker_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The hub's icon maker page: the playground opens the real icon maker and
/// its result lands in the preview.
void main() {
  testWidgets('opens the icon maker; "Use this" fills the preview', (t) async {
    t.view.physicalSize = const Size(420 * 3, 4000 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => AppUiConfig(child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: buildIconMakerPage(context),
            ),
          ),
        ),
      ),
    );
    expect(find.text('no icon (fallback)'), findsWidgets);

    await t.tap(find.text('Open').first);
    await t.pumpAndSettle();
    expect(find.text('Use this'), findsOneWidget);

    await t.tap(find.text('Use this'));
    await t.pumpAndSettle();
    expect(find.text('no icon (fallback)'), findsNWidgets(4));
    expect(find.textContaining('icon:'), findsOneWidget);
  });
}
