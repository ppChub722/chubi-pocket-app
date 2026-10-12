import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Apply to…" (owner 2026-10-13): the rows passed, in order, under the
/// title; a tap resolves that scope, a barrier tap null.
void main() {
  Future<BuildContext> pump(WidgetTester t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('shows the title and only the scopes passed, in order', (
    t,
  ) async {
    final ctx = await pump(t);
    final result = showEditScopeChoice(
      ctx,
      title: 'Apply to',
      options: const {
        EditScope.upcoming: 'All upcoming items',
        EditScope.all: 'All items',
      },
    );
    await t.pumpAndSettle();
    expect(find.text('Apply to'), findsOneWidget);
    expect(find.byType(PickerRow), findsNWidgets(2));
    final upcoming = t.getTopLeft(find.text('All upcoming items')).dy;
    final all = t.getTopLeft(find.text('All items')).dy;
    expect(upcoming, lessThan(all));
    await t.tap(find.text('All items'));
    await t.pumpAndSettle();
    expect(await result, EditScope.all);
  });

  testWidgets('dismissed → null', (t) async {
    final ctx = await pump(t);
    final result = showEditScopeChoice(
      ctx,
      title: 'Apply to',
      options: const {EditScope.thisOne: 'This item'},
    );
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(await result, isNull);
  });

  test('the five scopes', () {
    expect(EditScope.values, hasLength(5));
  });
}
