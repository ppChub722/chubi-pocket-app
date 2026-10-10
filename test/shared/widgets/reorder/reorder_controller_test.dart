import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/reorder/reorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<OutlineItem> o(String spec) => [
  for (final t in spec.split(' '))
    OutlineItem(t.split(':')[0], int.parse(t.split(':')[1])),
];

String s(List<OutlineItem> items) =>
    items.map((r) => '${r.id}:${r.level}').join(' ');

void main() {
  group('ReorderController', () {
    test('a move is one undo step; undo restores, dirty follows', () {
      final c = ReorderController(items: o('A:1 B:1 C:1'));
      c.select('C');
      expect(c.canMoveUp, isTrue);
      expect(c.canMoveDown, isFalse);
      c.moveUp();
      expect(s(c.items), 'A:1 C:1 B:1');
      expect(c.dirty, isTrue);
      expect(c.canUndo, isTrue);
      c.undo();
      expect(s(c.items), 'A:1 B:1 C:1');
      expect(c.dirty, isFalse);
    });

    test('dropping where it was picked up changes nothing (QA F2)', () {
      final c = ReorderController(items: o('A:1 A1:2 B:1'));
      expect(c.drop('A1', 1, 2), isFalse);
      expect(c.dirty, isFalse);
      expect(c.canUndo, isFalse);
    });

    test('undo keeps at most 5 steps', () {
      final c = ReorderController(items: o('A:1 B:1'))..select('A');
      for (var i = 0; i < 8; i++) {
        c.canMoveDown ? c.moveDown() : c.moveUp();
      }
      var undos = 0;
      while (c.canUndo) {
        c.undo();
        undos++;
      }
      expect(undos, 5);
    });

    test('→ under a collapsed sibling opens it (selection stays visible)', () {
      final collapsed = {'A'};
      final c = ReorderController(
        items: o('A:1 A1:2 B:1'),
        collapsed: collapsed,
      )..select('B');
      c.indent();
      expect(s(c.items), 'A:1 A1:2 B:2');
      expect(collapsed, isEmpty);
    });

    test('collapsing the selected row\'s parent deselects', () {
      final c = ReorderController(items: o('A:1 A1:2'))..select('A1');
      c.toggleCollapsed('A');
      expect(c.selectedId, isNull);
    });

    test('a flat list has no ← →', () {
      final c = ReorderController(items: o('A:1 B:1'), maxDepth: 1)
        ..select('B');
      expect(c.isTree, isFalse);
      expect(c.canIndent, isFalse);
      expect(c.canOutdent, isFalse);
    });
  });

  group('ReorderListScope + ReorderMoveBar', () {
    Future<ReorderController> pump(WidgetTester tester) async {
      final c = ReorderController(items: o('A:1 B:1 C:1'), maxDepth: 1);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('th'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListenableBuilder(
              listenable: c,
              builder: (context, _) => ReorderListScope(
                controller: c,
                scrollController: scroll,
                child: ListView(
                  controller: scroll,
                  children: [
                    for (final item in c.visible())
                      ReorderRow(
                        key: ValueKey(item.id),
                        id: item.id,
                        child: SizedBox(height: 56, child: Text(item.id)),
                      ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: ReorderMoveBar(controller: c),
          ),
        ),
      );
      return c;
    }

    testWidgets('tap selects → the bar moves it; tap again deselects', (
      tester,
    ) async {
      final c = await pump(tester);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(c.selectedId, 'A');
      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();
      expect(s(c.items), 'B:1 A:1 C:1');
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(c.selectedId, isNull);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('a drag from the handle moves the row at once', (tester) async {
      final c = await pump(tester);
      final handle = find.byIcon(Icons.drag_indicator).first; // A's
      final gesture = await tester.startGesture(tester.getCenter(handle));
      // Past C's middle: below every row.
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 16));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(s(c.items), 'B:1 C:1 A:1');
      expect(c.dirty, isTrue);
    });

    testWidgets('picked up and put back: not dirty (QA F2)', (tester) async {
      final c = await pump(tester);
      final handle = find.byIcon(Icons.drag_indicator).at(1); // B's
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(s(c.items), 'A:1 B:1 C:1');
      expect(c.dirty, isFalse);
    });
  });
}
