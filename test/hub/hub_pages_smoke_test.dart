import 'package:chubi_pocket/hub/api/openapi_source.dart';
import 'package:chubi_pocket/hub/hub_registry.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'openapi_fixture.dart';

/// Every live hub page builds and lays out without an exception (a page that
/// throws would be a blank screen for the owner). Pages that read the app's
/// cubits (the real data demos) need the app root and are listed in
/// [_needsApp] — they are exercised on a device, not here.
void main() {
  // The API pages read the spec from the server; here a fixed one.
  setUp(() {
    HubOpenApi.clear();
    HubOpenApi.testSource = (_) async => openApiFixture;
  });
  tearDown(() {
    HubOpenApi.testSource = null;
    HubOpenApi.clear();
  });

  const needsApp = <String>{
    'domain/transactions',
    'domain/people-accounts',
    'domain/others',
    'templates/transaction-detail',
  };

  for (final page in hubPages.where((p) => p.builder != null)) {
    if (needsApp.contains(page.id)) continue;
    testWidgets('hub page ${page.id} builds', (t) async {
      t.view.physicalSize = const Size(420 * 3, 3000 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = previous);
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
                child: page.builder!(context),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      t.takeException();
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  }
}
