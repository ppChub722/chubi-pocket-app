import 'package:pp_forge/pp_forge.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The final PpForgeInput (owner 2026-10-12): Field = ONE outlined frame, no fill;
/// In-card = underline; data types layered on both; locked = no frame.
void main() {
  labelTests();
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      // The app's filled theme must not leak into the field.
      theme: ThemeData(
        inputDecorationTheme: const InputDecorationTheme(filled: true),
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  testWidgets('Field: one frame, no fill anywhere', (t) async {
    await pump(t, const PpForgeInput(label: 'Name', hint: 'Placeholder'));
    final decorators = t.widgetList<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorators.where((d) => d.decoration.filled == true), isEmpty);
    // Exactly one decorator draws a border; the inner text field draws none.
    final bordered = decorators.where(
      (d) =>
          d.decoration.border is OutlineInputBorder ||
          d.decoration.enabledBorder is OutlineInputBorder,
    );
    expect(bordered.length, 1);
  });

  testWidgets('Field: error shows the message; disabled is dimmed', (t) async {
    await pump(
      t,
      const PpForgeInput(label: 'Email', errorText: 'Enter a valid email'),
    );
    expect(find.text('Enter a valid email'), findsOneWidget);
    await pump(t, const PpForgeInput(label: 'Name', enabled: false));
    final op = t.widget<Opacity>(
      find
          .ancestor(
            of: find.byType(InputDecorator),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(op.opacity, 0.38);
  });

  testWidgets('Field: the validator runs with the Form', (t) async {
    final key = GlobalKey<FormState>();
    final c = TextEditingController();
    await pump(
      t,
      Form(
        key: key,
        child: PpForgeInput(
          controller: c,
          label: 'Name',
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        ),
      ),
    );
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Required'), findsOneWidget);
    await t.enterText(find.byType(EditableText), 'Aom');
    expect(key.currentState!.validate(), isTrue);
  });

  testWidgets('types: amount, percent, reference', (t) async {
    final amount = TextEditingController();
    await pump(
      t,
      PpForgeInput(controller: amount, type: PpForgeInputType.amount),
    );
    await t.enterText(find.byType(EditableText), '1234567');
    expect(amount.text, '1,234,567');
    // The symbol is the app's, stuck to the number.
    expect(find.text('฿'), findsOneWidget);

    final pct = TextEditingController();
    await pump(
      t,
      PpForgeInput(controller: pct, type: PpForgeInputType.percent),
    );
    await t.enterText(find.byType(EditableText), '150');
    expect(pct.text, '100');
    expect(find.text('%'), findsOneWidget);

    final ref = TextEditingController();
    await pump(
      t,
      PpForgeInput(controller: ref, type: PpForgeInputType.reference),
    );
    await t.enterText(find.byType(EditableText), '12a-34');
    expect(ref.text, '1234');
  });

  testWidgets('locked: no field, the text and a 🔒', (t) async {
    final c = TextEditingController(text: 'aom@mail.com');
    await pump(t, PpForgeInput(controller: c, label: 'Email', locked: true));
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('aom@mail.com'), findsOneWidget);
    expect(find.byIcon(PpForgeIcons.lock), findsOneWidget);
  });

  testWidgets('In-card: an underline, no frame, no label', (t) async {
    await pump(t, const PpForgeInput.card(hint: 'What for?'));
    final d = t.widgetList<InputDecorator>(find.byType(InputDecorator)).first;
    expect(d.decoration.border, isA<UnderlineInputBorder>());
    expect(d.decoration.labelText, isNull);
  });
  testWidgets('percent takes decimals (default 2), clamped 0-100', (t) async {
    final c = TextEditingController();
    await pump(t, PpForgeInput(controller: c, type: PpForgeInputType.percent));
    await t.enterText(find.byType(EditableText), '33.567');
    expect(c.text, '33.56');
    await t.enterText(find.byType(EditableText), '100.5');
    expect(c.text, '100');
    final whole = TextEditingController();
    await pump(
      t,
      PpForgeInput(
        controller: whole,
        type: PpForgeInputType.percent,
        decimals: 0,
      ),
    );
    await t.enterText(find.byType(EditableText), '7.5');
    expect(whole.text, '75');
  });

  testWidgets('reference can allow letters', (t) async {
    final c = TextEditingController();
    await pump(
      t,
      PpForgeInput(
        controller: c,
        type: PpForgeInputType.reference,
        allowLetters: true,
      ),
    );
    await t.enterText(find.byType(EditableText), 'ab-12x');
    expect(c.text, 'ab-12x');
  });

  testWidgets('textAlign: start keeps a number on the left', (t) async {
    await pump(
      t,
      const PpForgeInput.card(
        type: PpForgeInputType.amount,
        hint: '0',
        textAlign: TextAlign.start,
      ),
    );
    final box = t.getRect(find.byType(InputDecorator).first);
    final symbol = t.getRect(find.text('฿'));
    expect(symbol.left - box.left, lessThan(24));
  });
}

void labelTests() {
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [sweetTheme.lightColors]),
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  testWidgets('card label: left of the underline / above it', (t) async {
    await t.pumpWidget(
      host(
        const Column(
          children: [
            PpForgeInput.card(label: 'ชื่อ', hint: 'h1'),
            PpForgeInput.card(
              label: 'จำนวนเงิน',
              labelPlacement: PpForgeInputLabelPlacement.above,
              hint: 'h2',
            ),
          ],
        ),
      ),
    );
    final left = t.getRect(find.text('ชื่อ'));
    final field1 = t.getRect(find.byType(TextField).first);
    expect(left.right, lessThanOrEqualTo(field1.left));
    final above = t.getRect(find.text('จำนวนเงิน'));
    final field2 = t.getRect(find.byType(TextField).last);
    expect(above.bottom, lessThanOrEqualTo(field2.top + 1));
  });

  testWidgets('title label shows only while editing', (t) async {
    final c = TextEditingController(text: 'x');
    for (final editing in [true, false]) {
      await t.pumpWidget(
        host(
          PpForgeInput.title(editing: editing, controller: c, label: 'ชื่อ'),
        ),
      );
      expect(find.text('ชื่อ'), editing ? findsOneWidget : findsNothing);
    }
  });
}
