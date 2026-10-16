import 'package:chubi_pocket/hub/pages/domain_budgets_page.dart';
import 'package:chubi_pocket/hub/pages/domain_progress_page.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The progress / budgets hub pages build and lay out without an exception
/// (until they are registered, the hub smoke test does not reach them).
void main() {
  final pages = <String, WidgetBuilder>{
    'progress': buildProgressPage,
    'budgets': buildBudgetsPage,
  };
  for (final e in pages.entries) {
    testWidgets('hub page ${e.key} builds', (t) async {
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
                child: e.value(context),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  }
}
