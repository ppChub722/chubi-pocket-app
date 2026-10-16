import 'package:chubi_pocket/hub/api/openapi_source.dart';
import 'package:chubi_pocket/hub/api/page_flows.dart';
import 'package:chubi_pocket/hub/pages/api_pages.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'openapi_fixture.dart';

/// The API section of the developer portal, fed a fixed spec.
const _flows = [
  PageFlow('transactions-list', 'Every transaction.', [
    FlowStep.open([FlowCall('listTransactions', note: 'rows + totals')]),
  ]),
  PageFlow('quick-create-sheet', 'Create a transaction.', [
    FlowStep.open([FlowCall('listTransactions'), FlowCall('listTransactions')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('createTransaction')]),
    FlowStep.action('Picker opened', [
      FlowCall.unspecified('GET', '/accounts', note: 'wallet picker'),
      FlowCall.unspecified('GET', '/tags'),
    ]),
  ]),
];

void main() {
  setUp(() {
    HubOpenApi.clear();
    HubOpenApi.testSource = (_) async => openApiFixture;
    HubOpenApi.testFlows = _flows;
  });
  tearDown(() {
    HubOpenApi.testFlows = null;
    HubOpenApi.testSource = null;
    HubOpenApi.clear();
  });

  Future<void> pump(WidgetTester t, WidgetBuilder page) async {
    t.view.physicalSize = const Size(420 * 3, 3000 * 3);
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
              child: page(context),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('schemas: fields with type and required', (t) async {
    await pump(t, buildApiSchemasPage);
    expect(find.text('2 of 2 schemas'), findsOneWidget);
    await t.tap(find.text('Transaction'));
    await t.pumpAndSettle();
    expect(find.text('amount'), findsOneWidget);
    expect(find.text('string | null'), findsOneWidget);
    expect(find.text('required'), findsOneWidget);
  });

  testWidgets('pages: coverage on top, badges, triggers, rows expand', (
    t,
  ) async {
    await pump(t, buildApiPagesPage);
    expect(find.text('Spec covers 3 of 4 registered routes'), findsOneWidget);
    expect(find.text('transactions-list'), findsOneWidget);
    // 1 call on open is on target; 2 is over it.
    expect(find.text('on open: 1 call'), findsOneWidget);
    expect(find.text('on open: 2 calls'), findsOneWidget);
    expect(find.text('1 over target'), findsOneWidget);

    // Open a page: its triggers and rows (a grey row for a call not in the spec).
    await t.tap(find.text('quick-create-sheet'));
    await t.pumpAndSettle();
    expect(find.text('Button "บันทึก"'.toUpperCase()), findsOneWidget);
    expect(find.text('not in spec yet'), findsNWidgets(2));

    // Tap a row: the detail expands in place.
    await t.tap(find.text('POST'));
    await t.pumpAndSettle();
    expect(find.text('split_count renamed to splits_count'), findsOneWidget);
    expect(find.textContaining('"note": "Lunch"'), findsOneWidget);
    // Used by: derived from the registry, not x-used-by.
    expect(find.text('quick-create-sheet'), findsWidgets);

    // The last group: spec endpoints no page lists.
    expect(find.text('Not used by any page'), findsOneWidget);
  });

  testWidgets('pages: search narrows by path', (t) async {
    await pump(t, buildApiPagesPage);
    await t.enterText(find.byType(TextField), 'transactions/{id}');
    await t.pump();
    expect(find.text('transactions-list'), findsNothing);
    expect(find.text('Not used by any page'), findsNothing);
  });

  testWidgets('a failing load shows the error and Retry', (t) async {
    HubOpenApi.testSource = (_) async => throw const FormatException('boom');
    await pump(t, buildApiPagesPage);
    expect(find.textContaining('boom'), findsOneWidget);
    HubOpenApi.testSource = (_) async => openApiFixture;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(find.text('Spec covers 3 of 4 registered routes'), findsOneWidget);
  });
}
