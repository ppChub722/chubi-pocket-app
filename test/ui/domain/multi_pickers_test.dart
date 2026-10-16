import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _rows = <CategoryPickerRow>[
  CategoryPickerRow(id: 'food', name: 'Food'),
  CategoryPickerRow(id: 'cafe', name: 'Cafe', parentId: 'food'),
  CategoryPickerRow(id: 'rent', name: 'Rent', sortOrder: 1),
];

final _catLabels = CategoryMultiPickerLabels(
  title: 'Cats',
  searchHint: 'search',
  includeChildren: 'with subs',
  confirm: (n) => 'Done ($n)',
  empty: 'empty',
  noMatch: 'none',
);

const _items = [
  AccountMultiPickItem(
    id: 'a',
    name: 'Cash',
    icon: Icons.payments_outlined,
    balance: '10.00',
  ),
  AccountMultiPickItem(id: 'b', name: 'Bank', icon: Icons.savings_outlined),
];

final _walletLabels = AccountMultiPickerLabels(
  title: 'Wallets',
  searchHint: 'search',
  confirm: (n) => 'Done ($n)',
  empty: 'empty',
  noMatch: 'none',
);

typedef _Probe = (bool Function(), Object? Function());

void main() {
  Future<_Probe> open(
    WidgetTester t,
    Future<Object?> Function(BuildContext) show,
  ) async {
    t.view.physicalSize = const Size(420, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var done = false;
    Object? result;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Builder(
            builder: (context) => PpForgeButton(
              label: 'open',
              onPressed: () async {
                result = await show(context);
                done = true;
              },
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return (() => done, () => result);
  }

  group('category multi picker', () {
    Future<_Probe> openCats(
      WidgetTester t, {
      List<CategoryMultiPick> initial = const [],
    }) => open(
      t,
      (c) => showCategoryMultiPicker(
        c,
        rows: _rows,
        labels: _catLabels,
        initial: initial,
      ),
    );

    testWidgets('toggle; switch only on picked rows with children', (t) async {
      await openCats(t);
      expect(find.byKey(const ValueKey('include-food')), findsNothing);
      await t.tap(find.text('Food'));
      await t.pump();
      expect(find.byKey(const ValueKey('include-food')), findsOneWidget);
      // A leaf never shows the switch.
      await t.tap(find.text('Rent'));
      await t.pump();
      expect(find.byKey(const ValueKey('include-rent')), findsNothing);
      expect(find.text('Done (2)'), findsOneWidget);
      await t.tap(find.text('Food'));
      await t.pump();
      expect(find.byKey(const ValueKey('include-food')), findsNothing);
      expect(find.text('Done (1)'), findsOneWidget);
    });

    testWidgets('confirm returns the list with include flag', (t) async {
      final r = await openCats(t);
      await t.tap(find.text('Food'));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('include-food')));
      await t.pump();
      await t.tap(find.text('Rent'));
      await t.pump();
      await t.tap(find.text('Done (2)'));
      await t.pumpAndSettle();
      expect(r.$2(), [
        (id: 'food', includeChildren: true),
        (id: 'rent', includeChildren: false),
      ]);
    });

    testWidgets('initial opens ancestors; empty result allowed', (t) async {
      final r = await openCats(
        t,
        initial: [(id: 'cafe', includeChildren: false)],
      );
      expect(find.text('Cafe'), findsOneWidget);
      await t.tap(find.text('Cafe'));
      await t.pump();
      await t.tap(find.text('Done (0)'));
      await t.pumpAndSettle();
      expect(r.$1(), isTrue);
      expect(r.$2(), isEmpty);
    });

    testWidgets('dismiss returns null', (t) async {
      final r = await openCats(t);
      await t.tapAt(const Offset(200, 20));
      await t.pumpAndSettle();
      expect(r.$1(), isTrue);
      expect(r.$2(), isNull);
    });
  });

  group('account multi picker', () {
    Future<_Probe> openWallets(
      WidgetTester t, {
      List<String> initial = const [],
    }) => open(
      t,
      (c) => showAccountMultiPicker(
        c,
        wallets: _items,
        labels: _walletLabels,
        initial: initial,
      ),
    );

    testWidgets('toggle, balance only when given, confirm', (t) async {
      final r = await openWallets(t);
      expect(find.text('10.00'), findsOneWidget);
      await t.tap(find.text('Bank'));
      await t.pump();
      await t.tap(find.text('Cash'));
      await t.pump();
      await t.tap(find.text('Done (2)'));
      await t.pumpAndSettle();
      expect(r.$2(), ['b', 'a']);
    });

    testWidgets('empty allowed and dismiss is null', (t) async {
      final r = await openWallets(t, initial: ['a']);
      await t.tap(find.text('Cash'));
      await t.pump();
      await t.tap(find.text('Done (0)'));
      await t.pumpAndSettle();
      expect(r.$2(), isEmpty);

      final d = await openWallets(t);
      await t.tapAt(const Offset(200, 20));
      await t.pumpAndSettle();
      expect(d.$2(), isNull);
    });
  });
}
