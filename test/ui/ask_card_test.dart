import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester t, {
    bool busy = false,
    VoidCallback? no,
    VoidCallback? yes,
  }) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      home: Scaffold(
        body: AskCard(
          message: 'Update?',
          noLabel: 'No',
          yesLabel: 'Yes',
          busy: busy,
          onNo: no ?? () {},
          onYes: yes ?? () {},
        ),
      ),
    ),
  );

  testWidgets('message and the two answers', (t) async {
    var no = 0, yes = 0;
    await pump(t, no: () => no++, yes: () => yes++);
    expect(find.text('Update?'), findsOneWidget);
    await t.tap(find.text('No'));
    await t.tap(find.text('Yes'));
    expect([no, yes], [1, 1]);
  });

  testWidgets('busy disables both', (t) async {
    var taps = 0;
    await pump(t, busy: true, no: () => taps++, yes: () => taps++);
    await t.tap(find.text('No'));
    expect(taps, 0);
  });
}
