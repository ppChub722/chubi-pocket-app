import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The kit gaps of the all-hands pass: PpForgeInput.card options, the date
/// picker, CollapsibleSection, SectionHeader's leading slot.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets(
    'PpForgeInput.card: no underline in view mode, underline on focus',
    (t) async {
      await pump(
        t,
        const PpForgeInput.card(hint: 'What for?', underline: false),
      );
      InputDecorator deco() =>
          t.widgetList<InputDecorator>(find.byType(InputDecorator)).first;
      expect(deco().decoration.enabledBorder, isA<InputBorder>());
      expect(deco().decoration.enabledBorder, InputBorder.none);
      await t.tap(find.byType(EditableText));
      await t.pump();
      expect(deco().decoration.focusedBorder, isA<UnderlineInputBorder>());
    },
  );

  testWidgets('PpForgeInput.card: hint hidden while focused; focus colour', (
    t,
  ) async {
    await pump(
      t,
      const PpForgeInput.card(
        hint: '0',
        hideHintOnFocus: true,
        focusColor: Colors.red,
        type: PpForgeInputType.amount,
        symbolScale: 0.7,
        style: TextStyle(fontSize: 40),
      ),
    );
    expect(find.text('0'), findsOneWidget);
    await t.tap(find.byType(EditableText));
    await t.pump();
    expect(find.text('0'), findsNothing);
    final deco = t
        .widgetList<InputDecorator>(find.byType(InputDecorator))
        .first
        .decoration;
    expect(
      (deco.focusedBorder as UnderlineInputBorder).borderSide.color,
      Colors.red,
    );
    // The symbol is 0.7 of the digits.
    final symbol = t.widget<Text>(find.text('฿'));
    expect(symbol.style?.fontSize, closeTo(28, 0.01));
  });

  testWidgets('showPpForgeDatePicker: tapping a day picks it; Today; Clear', (
    t,
  ) async {
    PpForgeDateResult? got;
    await pump(
      t,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            got = await showPpForgeDatePicker(
              context,
              initial: DateTime(2026, 10, 14),
              first: DateTime(2026, 10, 1),
              last: DateTime(2026, 10, 31),
              clearable: true,
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('20'));
    await t.pumpAndSettle();
    expect(got, isA<PpForgeDatePicked>());
    expect((got! as PpForgeDatePicked).date, DateTime(2026, 10, 20));

    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.text('Clear'));
    await t.pumpAndSettle();
    expect(got, isA<PpForgeDateCleared>());
  });

  testWidgets('CollapsibleSection: hint open, summary closed, toggles', (
    t,
  ) async {
    await pump(
      t,
      const CollapsibleSection(
        title: 'Split',
        hint: 'the hint',
        summary: '2 people',
        initiallyOpen: false,
        children: [Text('BODY')],
      ),
    );
    expect(find.text('2 people'), findsOneWidget);
    expect(find.text('the hint'), findsNothing);
    expect(find.text('BODY'), findsNothing);
    await t.tap(find.text('Split'));
    await t.pumpAndSettle();
    expect(find.text('the hint'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    expect(find.text('2 people'), findsNothing);
  });

  testWidgets('CollapsibleSection: not collapsible is always open', (t) async {
    await pump(
      t,
      const CollapsibleSection(
        title: 'Details',
        collapsible: false,
        children: [Text('BODY')],
      ),
    );
    await t.tap(find.text('Details'));
    await t.pumpAndSettle();
    expect(find.text('BODY'), findsOneWidget);
  });

  testWidgets('SectionHeader: the leading icon comes before the title', (
    t,
  ) async {
    await pump(
      t,
      const SectionHeader(
        title: 'To do',
        leading: Icon(Icons.checklist, key: ValueKey('mark')),
      ),
    );
    final icon = t.getTopLeft(find.byKey(const ValueKey('mark'))).dx;
    final title = t.getTopLeft(find.text('To do')).dx;
    expect(icon, lessThan(title));
  });
  testWidgets('SelectionToolbar: actions dimmed until something is selected', (
    t,
  ) async {
    var tapped = 0;
    Widget bar(int picked) => SelectionToolbar(
      selected: picked,
      total: 5,
      onSelectAll: () {},
      actions: [
        SelectionAction(
          label: 'Colour',
          icon: Icons.palette,
          onTap: () => tapped++,
        ),
        SelectionAction(
          label: 'Import',
          icon: Icons.download,
          needsSelection: false,
          onTap: () => tapped += 10,
        ),
      ],
      onDelete: () {},
    );
    await pump(t, bar(0));
    await t.tap(find.text('Colour'), warnIfMissed: false);
    expect(tapped, 0, reason: 'dimmed with nothing selected');
    await t.tap(find.text('Import'));
    expect(tapped, 10, reason: 'always available');
    await pump(t, bar(2));
    await t.tap(find.text('Colour'));
    expect(tapped, 11);
    expect(find.text('2/5'), findsOneWidget);
  });

  testWidgets('TileCard in a CardGrid taps; CenteredFormBody caps the width', (
    t,
  ) async {
    var tapped = false;
    await pump(
      t,
      CardGrid(
        children: [
          TileCard(
            icon: Icons.wallet,
            title: 'Wallets',
            subtitle: 'Accounts',
            color: Colors.teal,
            onTap: () => tapped = true,
          ),
        ],
      ),
    );
    await t.tap(find.text('Wallets'));
    expect(tapped, isTrue);
    t.view.physicalSize = const Size(1600, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CenteredFormBody(child: SizedBox(height: 40, width: 2000)),
        ),
      ),
    );
    expect(t.getSize(find.byType(ConstrainedBox).last).width, 400);
  });

  testWidgets('PpForgeMessage icon override; MoneyListTile dimmed', (t) async {
    await pump(
      t,
      const PpForgeMessage(
        message: 'Locked',
        tone: Tone.warning,
        icon: Icons.lock,
      ),
    );
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.byIcon(PpForgeIcons.warning), findsNothing);
    await pump(
      t,
      const MoneyListTile(
        leading: SizedBox(),
        title: 'Old',
        amount: -10,
        dimmed: true,
      ),
    );
    final o = t.widget<Opacity>(
      find.ancestor(of: find.text('Old'), matching: find.byType(Opacity)).first,
    );
    expect(o.opacity, 0.55);
  });

  testWidgets('PickerRow chevron; PickerCreateRow(null) is dimmed', (t) async {
    await pump(
      t,
      Column(
        children: [
          PickerRow(title: 'Bank', chevron: true, onTap: () {}),
          const PickerCreateRow(label: 'New', onTap: null),
        ],
      ),
    );
    expect(find.byIcon(PpForgeIcons.chevronRight), findsOneWidget);
    expect(
      t
          .widget<Opacity>(
            find
                .ancestor(of: find.text('New'), matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      0.38,
    );
  });
}
