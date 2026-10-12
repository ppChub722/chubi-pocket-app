import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PickCard keeps ONE height per variant (owner 2026-10-12): empty, picked and
/// error are the same height, and the error never adds a line below the card.
void main() {
  Future<double> heightOf(WidgetTester t, PickCard card) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 340, child: card),
          ),
        ),
      ),
    );
    return t.getSize(find.byType(PickCard)).height;
  }

  PickCard three({String? value, String? error, Widget? subtitle}) => PickCard(
    label: 'Wallet',
    placeholder: 'Choose a wallet',
    value: value,
    subtitle: subtitle,
    errorText: error,
    fixedHeight: true,
    reserveSubtitle: true,
    leading: const PickCardEmptyIcon(AppIcons.wallet),
    onTap: () {},
  );

  PickCard two({String? value, String? error}) => PickCard(
    label: 'Payer',
    fixedHeight: true,
    placeholder: 'Choose a member',
    value: value,
    errorText: error,
    leading: const PickCardEmptyIcon(AppIcons.contact),
    onTap: () {},
  );

  testWidgets(
    '3-line variant: empty = picked = picked without subtitle = error',
    (t) async {
      final empty = await heightOf(t, three());
      final picked = await heightOf(
        t,
        three(value: 'Savings', subtitle: const Text('Balance 12,400')),
      );
      final bare = await heightOf(t, three(value: 'Savings'));
      final error = await heightOf(t, three(error: 'Pick a wallet first'));
      expect(picked, empty);
      expect(bare, empty);
      expect(error, empty);
    },
  );

  testWidgets('2-line variant: empty = picked = error', (t) async {
    final empty = await heightOf(t, two());
    final picked = await heightOf(t, two(value: 'Aom'));
    final error = await heightOf(t, two(error: 'Pick who paid'));
    expect(picked, empty);
    expect(error, empty);
  });

  testWidgets('the error text is inside the card', (t) async {
    await heightOf(t, three(error: 'Pick a wallet first'));
    expect(
      find.descendant(
        of: find.byType(PickCard),
        matching: find.text('Pick a wallet first'),
      ),
      findsOneWidget,
    );
  });
}
