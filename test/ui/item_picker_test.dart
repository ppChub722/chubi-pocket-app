import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// food ─ cafe ─ latte
//      └ market
// rent
final _tree = PickerTree([
  (id: 'food', parentId: null),
  (id: 'cafe', parentId: 'food'),
  (id: 'latte', parentId: 'cafe'),
  (id: 'market', parentId: 'food'),
  (id: 'rent', parentId: null),
]);

const _items = [
  PickerItem(id: 'food', title: 'Food', group: 'out'),
  PickerItem(id: 'cafe', title: 'Cafe', parentId: 'food', group: 'out'),
  PickerItem(id: 'market', title: 'Market', parentId: 'food', group: 'out'),
  PickerItem(id: 'rent', title: 'Rent', group: 'out'),
  PickerItem(id: 'salary', title: 'Salary', group: 'in'),
];

typedef _Probe = (bool Function(), PickerResult? Function());

void main() {
  group('PickerSelection', () {
    test('separate: every id on its own', () {
      final s = PickerSelection(mode: PickerChildren.separate)
        ..toggle('food', _tree);
      expect(s.shownTicked('cafe', _tree), isFalse);
      expect(s.shownCount(_tree), 1);
      s.toggle('food', _tree);
      expect(s.ids, isEmpty);
    });

    test('toggle: the box takes every sub-item in', () {
      final s = PickerSelection(mode: PickerChildren.toggle)
        ..toggle('food', _tree);
      expect(s.takesChildren('food'), isFalse);
      s.setTakesChildren('food', true, _tree);
      expect(s.shownTicked('latte', _tree), isTrue);
      expect(s.shownCount(_tree), 4);
      expect(s.withChildren, {'food'});
    });

    test('toggle: unticking a covered sub-item keeps the parent', () {
      final s = PickerSelection(
        mode: PickerChildren.toggle,
        withChildren: const ['food'],
      )..toggle('cafe', _tree);
      expect(s.takesChildren('food'), isFalse);
      expect(s.isPicked('food'), isTrue);
      expect(s.isPicked('market'), isTrue);
      expect(s.shownTicked('cafe', _tree), isFalse);
      expect(s.shownTicked('latte', _tree), isFalse);
    });

    test('toggle: ticking every sub-item folds into the parent', () {
      final s = PickerSelection(mode: PickerChildren.toggle)
        ..toggle('food', _tree)
        ..toggle('cafe', _tree)
        ..toggle('latte', _tree)
        ..toggle('market', _tree);
      expect(s.ids, ['food']);
      expect(s.takesChildren('food'), isTrue);
    });

    test('normalize drops stored sub-items a pick takes in', () {
      final s = PickerSelection(
        mode: PickerChildren.toggle,
        ids: const ['cafe', 'rent'],
        withChildren: const ['food'],
      )..normalize(_tree);
      expect(s.ids.toSet(), {'food', 'rent'});
    });

    test('always: a parent takes its sub-items in', () {
      final s = PickerSelection(mode: PickerChildren.always)
        ..toggle('food', _tree);
      expect(s.withChildren, {'food'});
      expect(s.shownTicked('latte', _tree), isTrue);
    });

    test('always: unticking a sub-item drops the parent, keeps the rest', () {
      final s = PickerSelection(
        mode: PickerChildren.always,
        withChildren: const ['food'],
      )..toggle('latte', _tree);
      expect(s.isPicked('food'), isFalse);
      expect(s.isPicked('cafe'), isFalse);
      expect(s.isPicked('market'), isTrue);
      expect(s.shownTicked('latte', _tree), isFalse);
    });
  });

  group('ItemPickerSheet', () {
    Future<_Probe> open(
      WidgetTester t,
      ItemPickerSheet sheet, {
      bool settle = true,
    }) async {
      t.view.physicalSize = const Size(420, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      var done = false;
      PickerResult? result;
      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          home: Scaffold(
            body: Builder(
              builder: (context) => AppButton(
                label: 'open',
                onPressed: () async {
                  result = await showItemPicker(context, sheet);
                  done = true;
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      if (settle) {
        await t.pumpAndSettle();
      } else {
        await t.pump(const Duration(seconds: 1));
      }
      return (() => done, () => result);
    }

    testWidgets('single: a tap answers the id', (t) async {
      final (done, result) = await open(
        t,
        const ItemPickerSheet(title: 'Pick', items: _items),
      );
      await t.tap(find.text('Rent'));
      await t.pumpAndSettle();
      expect(done(), isTrue);
      expect(result()!.id, 'rent');
    });

    testWidgets('single: the none row answers none', (t) async {
      final (_, result) = await open(
        t,
        const ItemPickerSheet(
          title: 'Pick',
          items: _items,
          none: PickerNone(label: 'Nothing'),
        ),
      );
      await t.tap(find.text('Nothing'));
      await t.pumpAndSettle();
      expect(result()!.none, isTrue);
    });

    testWidgets('groups get headings; filter tabs narrow the list', (t) async {
      await open(
        t,
        ItemPickerSheet(
          title: 'Pick',
          items: _items,
          groups: const [PickerGroup('out', 'Out'), PickerGroup('in', 'In')],
          filters: [
            PickerFilter('All', (_) => true),
            PickerFilter('In only', (i) => i.group == 'in'),
          ],
        ),
      );
      expect(find.text('Out'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      await t.tap(find.text('In only'));
      await t.pumpAndSettle();
      expect(find.text('Rent'), findsNothing);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets('a sub-item shows once its parent is expanded', (t) async {
      await open(t, const ItemPickerSheet(title: 'Pick', items: _items));
      expect(find.text('Cafe'), findsNothing);
      await t.tap(find.byIcon(AppIcons.expand));
      await t.pumpAndSettle();
      expect(find.text('Cafe'), findsOneWidget);
    });

    testWidgets('multi toggle: include box, count and answer', (t) async {
      final (_, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Pick',
          items: _items,
          multi: true,
          children: PickerChildren.toggle,
          includeChildrenLabel: 'with subs',
          confirmLabel: (n) => 'Done ($n)',
        ),
      );
      await t.tap(find.text('Food'));
      await t.pumpAndSettle();
      expect(find.text('Done (1)'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('include-food')));
      await t.pumpAndSettle();
      expect(find.text('Done (3)'), findsOneWidget);
      await t.tap(find.text('Done (3)'));
      await t.pumpAndSettle();
      expect(result()!.ids, ['food']);
      expect(result()!.withChildren, {'food'});
    });

    testWidgets('multi none row is a tick of its own', (t) async {
      final (_, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Pick',
          items: _items,
          multi: true,
          none: const PickerNone(label: 'Nothing'),
          confirmLabel: (n) => 'Done ($n)',
        ),
      );
      await t.tap(find.text('Nothing'));
      await t.tap(find.text('Rent'));
      await t.pumpAndSettle();
      await t.tap(find.text('Done (2)'));
      await t.pumpAndSettle();
      expect(result()!.none, isTrue);
      expect(result()!.ids, ['rent']);
    });

    testWidgets('chips: creating from the search ticks the new item', (
      t,
    ) async {
      final (_, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Tags',
          items: const [PickerItem(id: 'work', title: 'work')],
          layout: PickerLayout.chips,
          multi: true,
          create: PickerCreate(
            label: (typed) => typed.isEmpty ? 'New' : 'Create "$typed"',
            onCreate: (typed) async => 'id-$typed',
            fromSearch: true,
          ),
          confirmLabel: (n) => 'Done ($n)',
        ),
      );
      await t.tap(find.byIcon(AppIcons.search));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'trip');
      await t.pumpAndSettle();
      await t.tap(find.text('Create "trip"'));
      await t.pumpAndSettle();
      await t.tap(find.text('Done (1)'));
      await t.pumpAndSettle();
      expect(result()!.ids, ['id-trip']);
    });

    testWidgets('name row: save shows only while it has focus', (t) async {
      final (_, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Who',
          items: _items,
          freeText: PickerFreeText(hint: 'New name', saveLabel: (_) => 'Save'),
        ),
      );
      expect(find.text('Save'), findsNothing);
      await t.tap(find.text('New name'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'Noi');
      await t.pumpAndSettle();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(result()!.text, 'Noi');
    });

    testWidgets('empty list shows its text', (t) async {
      await open(
        t,
        const ItemPickerSheet(
          title: 'Pick',
          items: [],
          emptyText: 'Nothing yet',
        ),
      );
      expect(find.text('Nothing yet'), findsOneWidget);
    });

    testWidgets('load: fetches on open, error offers a retry', (t) async {
      var calls = 0;
      await open(
        t,
        ItemPickerSheet(
          title: 'Pick',
          items: const [],
          load: () async {
            calls++;
            if (calls == 1) throw 'down';
            return const [PickerItem(id: 'rent', title: 'Rent')];
          },
        ),
      );
      expect(find.text('Rent'), findsNothing);
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('live: items, loading and error follow the listenable', (
      t,
    ) async {
      final live = ValueNotifier(const PickerData([], loading: true));
      addTearDown(live.dispose);
      await open(
        t,
        ItemPickerSheet(title: 'Pick', items: const [], live: live),
        settle: false,
      );
      expect(find.byType(SkeletonListTile), findsWidgets);
      live.value = const PickerData([PickerItem(id: 'rent', title: 'Rent')]);
      await t.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('onConfirm keeps the sheet open until it succeeds', (t) async {
      var tries = 0;
      final (done, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Pick',
          items: _items,
          multi: true,
          minPicks: 1,
          confirmLabel: (n) => 'Done ($n)',
          onConfirm: (_) async => ++tries > 1,
        ),
      );
      await t.tap(find.text('Done (0)'));
      await t.pumpAndSettle();
      expect(tries, 0, reason: 'below minPicks the button is off');
      await t.tap(find.text('Rent'));
      await t.pumpAndSettle();
      await t.tap(find.text('Done (1)'));
      await t.pumpAndSettle();
      expect(done(), isFalse);
      await t.tap(find.text('Done (1)'));
      await t.pumpAndSettle();
      expect(done(), isTrue);
      expect(result()!.ids, ['rent']);
    });

    testWidgets('a pinned action sits in the footer and answers its id', (
      t,
    ) async {
      final (_, result) = await open(
        t,
        const ItemPickerSheet(
          title: 'Pick',
          items: _items,
          actions: [
            PickerAction(
              id: 'new',
              label: 'New one',
              icon: AppIcons.add,
              pinned: true,
            ),
          ],
        ),
      );
      await t.tap(find.text('New one'));
      await t.pumpAndSettle();
      expect(result()!.action, 'new');
    });

    testWidgets('name row starts with the name typed before', (t) async {
      final (_, result) = await open(
        t,
        ItemPickerSheet(
          title: 'Event',
          items: const [],
          freeText: PickerFreeText(
            hint: 'Event name',
            saveLabel: (typed) => 'Create "$typed"',
            initial: 'Trip',
          ),
        ),
      );
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('Create "Trip"'), findsNothing);
      await t.tap(find.text('Trip'));
      await t.pumpAndSettle();
      await t.tap(find.text('Create "Trip"'));
      await t.pumpAndSettle();
      expect(result()!.text, 'Trip');
    });

    testWidgets('create takes the name from the name row', (t) async {
      String? got;
      await open(
        t,
        ItemPickerSheet(
          title: 'Who',
          items: _items,
          freeText: PickerFreeText(
            hint: 'New name',
            saveLabel: (_) => 'Save',
            initial: 'Noi',
          ),
          create: PickerCreate(
            label: (_) => 'Add contact',
            onCreate: (typed) async {
              got = typed;
              return null;
            },
          ),
        ),
      );
      await t.tap(find.text('Add contact'));
      await t.pumpAndSettle();
      expect(got, 'Noi');
    });

    testWidgets('create from the search hides on an exact name', (t) async {
      await open(
        t,
        ItemPickerSheet(
          title: 'Tags',
          items: const [PickerItem(id: 'work', title: 'work')],
          layout: PickerLayout.chips,
          multi: true,
          create: PickerCreate(
            label: (typed) => typed.isEmpty ? 'New' : 'Create "$typed"',
            onCreate: (typed) async => typed,
            fromSearch: true,
          ),
          confirmLabel: (n) => 'Done ($n)',
        ),
      );
      await t.tap(find.byIcon(AppIcons.search));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'work');
      await t.pumpAndSettle();
      expect(find.text('Create "work"'), findsNothing);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('a none row can stay while searching', (t) async {
      await open(
        t,
        ItemPickerSheet(
          title: 'Who',
          items: _items,
          none: const PickerNone(
            label: 'Keep the name',
            subtitle: 'not linked',
            showWhileSearching: true,
          ),
          searchable: true,
        ),
      );
      await t.tap(find.byIcon(AppIcons.search));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'ren');
      await t.pumpAndSettle();
      expect(find.text('Keep the name'), findsOneWidget);
      expect(find.text('not linked'), findsOneWidget);
    });
  });
}
