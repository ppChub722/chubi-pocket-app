import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saving goals v2 kit: MilestoneRow, SavingHistoryChart, SavingTxRow,
/// SavingMoveSheet, CloseGoalDialog.
void main() {
  Future<void> pump(WidgetTester t, Widget child, {double width = 400}) =>
      t.pumpWidget(
        MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            extensions: [
              ThemeRegistry.byId(
                ThemeRegistry.defaultThemeId,
              ).colorsFor(Brightness.light),
            ],
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      );

  group('SavingChartGeometry', () {
    test('points map inside the plot box', () {
      final g = SavingChartGeometry.forSeries(
        size: const Size(330, 135),
        actual: const [10, 20, 40],
        projection: const [50, 60],
        target: 80,
        slots: 8,
      );
      expect(g.slots, 8);
      expect(g.maxValue, 80);
      for (var i = 0; i < 8; i++) {
        for (final v in const [0.0, 40.0, 80.0, 500.0, -5.0]) {
          final p = g.point(i, v);
          expect(g.plot.inflate(0.001).contains(p), isTrue, reason: '$i/$v');
        }
      }
      expect(g.x(0), g.plot.left);
      expect(g.x(7), g.plot.right);
      expect(g.y(80), g.plot.top);
      expect(g.y(0), g.plot.bottom);
    });

    test('the top grows with a value above the target', () {
      final g = SavingChartGeometry.forSeries(
        size: const Size(300, 100),
        actual: const [120],
        projection: const [],
        target: 80,
      );
      expect(g.maxValue, 120);
    });

    test('empty series and zero target are safe', () {
      final g = SavingChartGeometry.forSeries(
        size: const Size(300, 100),
        actual: const [],
        projection: const [],
        target: 0,
      );
      expect(g.slots, 1);
      expect(g.maxValue, 1);
      expect(g.plot.inflate(0.001).contains(g.point(0, 0)), isTrue);
      expect(g.y(double.nan), g.plot.bottom);
    });
  });

  testWidgets('SavingHistoryChart paints full, empty and skeleton', (t) async {
    await pump(
      t,
      const Column(
        children: [
          SavingHistoryChart(
            actual: [10, 20, 30],
            projection: [40, 50],
            target: 80,
            monthLabels: ['a', 'b', 'c', 'd', 'e', 'f'],
            targetLabel: 'Goal 80',
            caption: 'cap',
            actualLegend: 'actual',
            neededLegend: 'needed',
          ),
          SavingHistoryChart(actual: [], target: 0),
          SavingHistoryChart.skeleton(),
        ],
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('actual'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('MilestoneRow renders every step', (t) async {
    await pump(
      t,
      const MilestoneRow(
        steps: [
          MilestoneStep(label: '25%', state: MilestoneState.done, glyph: '✓'),
          MilestoneStep(label: '50%', state: MilestoneState.next, glyph: '50'),
          MilestoneStep(label: '100%', state: MilestoneState.todo, glyph: 'X'),
        ],
      ),
    );
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
  });

  group('SavingTxRow', () {
    const lead = SizedBox(width: 36, height: 36);
    Future<double> h(WidgetTester t, Widget w) async {
      await pump(t, Column(children: [w]));
      return t.getSize(find.byWidget(w)).height;
    }

    testWidgets('same height as TxRow, every kind and draft', (t) async {
      final tx = await h(
        t,
        const TxRow(
          leading: lead,
          title: 'Lunch',
          amount: -120,
          walletLabel: 'KBank',
          category: 'Food',
        ),
      );
      for (final k in SavingTxKind.values) {
        final row = await h(
          t,
          SavingTxRow(
            kind: k,
            title: 'Save',
            walletLabel: 'KBank',
            from: 'Spare',
            to: 'Trip',
            amount: 100,
            source: const AppChip(label: 'Rec', size: ChipSize.mini),
          ),
        );
        expect(row, closeTo(tx, 1), reason: '$k');
      }
      final draft = await h(
        t,
        const SavingTxRow(
          kind: SavingTxKind.deposit,
          draft: true,
          title: 'Save',
          walletLabel: 'KBank',
          draftChips: [AppChip(label: 'Sav', size: ChipSize.mini)],
          to: 'Trip',
          amount: 100,
        ),
      );
      expect(draft, closeTo(tx, 1));
    });

    testWidgets('signs: deposit + / withdraw -; dimmed fades', (t) async {
      await pump(
        t,
        const Column(
          children: [
            SavingTxRow(
              kind: SavingTxKind.deposit,
              title: 'A',
              walletLabel: 'W',
              to: 'T',
              amount: 5,
            ),
            SavingTxRow(
              kind: SavingTxKind.withdraw,
              title: 'B',
              walletLabel: 'W',
              from: 'T',
              amount: 5,
              dimmed: true,
            ),
          ],
        ),
      );
      expect(find.text('+'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
      final fade = t.widget<Opacity>(
        find.ancestor(of: find.text('B'), matching: find.byType(Opacity)),
      );
      expect(fade.opacity, lessThan(1));
    });
  });

  group('SavingMoveSheet', () {
    Future<void> open(
      WidgetTester t,
      void Function(List<SavingMoveSplit>?) sink,
    ) async {
      await pump(
        t,
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => sink(
              await showSavingMoveSheet(
                ctx,
                title: 'Move',
                from: const SavingMoveEnd(caption: 'From', name: 'Trip'),
                to: const SavingMoveEnd(caption: 'To', name: 'Car'),
                amount: 45000,
                splits: const [
                  SavingSplitRow(walletId: 'a', name: 'A', amount: 40000),
                  SavingSplitRow(walletId: 'b', name: 'B', amount: 5000),
                ],
                amountLabel: 'Amount',
                splitTitle: 'Split',
                editLabel: 'Edit',
                saveLabel: 'Go',
                sumOkText: (s) => 'ok $s',
                sumOffText: (s, a) => 'off $s/$a',
                autoSplit: (a) => [
                  (walletId: 'a', amount: a > 40000 ? 40000 : a),
                  (walletId: 'b', amount: a > 40000 ? a - 40000 : 0),
                ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('valid split saves; an off sum disables save', (t) async {
      List<SavingMoveSplit>? got;
      await open(t, (r) => got = r);
      expect(find.text('ok 45000.0'), findsOneWidget);
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      final fields = find.byType(EditableText);
      await t.enterText(fields.last, '4,000');
      await t.pumpAndSettle();
      expect(find.textContaining('off '), findsOneWidget);
      expect(
        t.widget<AppButton>(find.widgetWithText(AppButton, 'Go')).onPressed,
        isNull,
      );
      await t.enterText(fields.last, '5,000');
      await t.pumpAndSettle();
      await t.tap(find.text('Go'));
      await t.pumpAndSettle();
      expect(got, [
        (walletId: 'a', amount: 40000.0),
        (walletId: 'b', amount: 5000.0),
      ]);
    });

    testWidgets('changing the amount re-splits automatically', (t) async {
      List<SavingMoveSplit>? got;
      await open(t, (r) => got = r);
      await t.enterText(find.byType(EditableText).first, '30,000');
      await t.pumpAndSettle();
      await t.tap(find.text('Go'));
      await t.pumpAndSettle();
      // b = 0 is dropped from the result.
      expect(got, [(walletId: 'a', amount: 30000.0)]);
    });
  });

  group('CloseGoalDialog', () {
    Future<void> open(
      WidgetTester t,
      void Function(CloseGoalChoice?) sink,
    ) async {
      await pump(
        t,
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => sink(
              await showCloseGoalDialog(
                ctx,
                title: 'Close',
                message: 'Where?',
                returnsTitle: 'If back',
                returns: const [(wallet: 'KBank', amount: 40000)],
                toSpareLabel: 'Spare',
                backToWalletsLabel: 'Back',
                cancelLabel: 'Cancel',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    for (final (label, want) in [
      ('Spare', CloseGoalChoice.toSpare),
      ('Back', CloseGoalChoice.backToWallets),
      ('Cancel', null),
    ]) {
      testWidgets('$label resolves $want', (t) async {
        Object? got = 'unset';
        await open(t, (r) => got = r);
        expect(find.text('KBank'), findsOneWidget);
        await t.tap(find.text(label));
        await t.pumpAndSettle();
        expect(got, want);
      });
    }
  });
}
