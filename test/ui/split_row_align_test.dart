import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every name in a split row starts at the same x: "my share", a typed
/// (framed) name and a contact's highlighted name (owner 2026-10-12).
void main() {
  testWidgets('me · typed · contact · linked names share one text x', (
    t,
  ) async {
    final c = TextEditingController(text: 'Mali');
    final f = FocusNode();
    Widget row(Widget name) => SplitRow(
      avatar: const SizedBox(width: 36),
      name: name,
      amount: const SizedBox(width: 90, height: SplitRow.height),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              row(const SplitRowName.muted('My share')),
              row(SplitRowName.input(controller: c, focusNode: f)),
              row(const SplitRowName.picked('Bee')),
              row(const SplitRowName.picked('Ton')),
            ],
          ),
        ),
      ),
    );
    final me = t.getTopLeft(find.text('My share')).dx;
    final typed = t.getTopLeft(find.byType(EditableText)).dx;
    final bee = t.getTopLeft(find.text('Bee')).dx;
    final ton = t.getTopLeft(find.text('Ton')).dx;
    expect(typed, closeTo(me, 0.6), reason: 'typed vs me');
    expect(bee, closeTo(me, 0.6), reason: 'contact vs me');
    expect(ton, closeTo(bee, 0.01));
  });
}
