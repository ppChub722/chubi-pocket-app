import 'package:chubi_pocket/ui/ui.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one text input (owner 2026-10-12): kinds field / inline / title /
/// search, the looks, and the small atoms around it.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [sweetTheme.lightColors]),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  testWidgets('field: types, shows the label, error text and counter option', (
    t,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    String? changed;
    await pump(
      t,
      PpForgeInput(
        controller: c,
        label: 'Name',
        errorText: 'Taken',
        maxLength: 10,
        showCounter: true,
        onChanged: (v) => changed = v,
      ),
    );
    await t.enterText(find.byType(TextField), 'abc');
    expect(changed, 'abc');
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Taken'), findsOneWidget);
    expect(find.textContaining('/10'), findsOneWidget);
  });

  testWidgets('obscurable: the eye toggles the text', (t) async {
    await pump(t, const PpForgeInput(label: 'Password', obscurable: true));
    TextField field() => t.widget<TextField>(find.byType(TextField));
    expect(field().obscureText, isTrue);
    await t.tap(find.byType(IconButton));
    await t.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('inline: read-only in view, long-press enters edit, hint shown', (
    t,
  ) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    var entered = 0;
    await pump(
      t,
      PpForgeInput.inline(
        editing: false,
        controller: c,
        viewHint: 'Long-press to edit',
        onEnterEdit: () => entered++,
      ),
    );
    expect(find.text('Long-press to edit'), findsOneWidget);
    expect(t.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    await t.longPress(find.byType(PpForgeInput));
    expect(entered, 1);
  });

  testWidgets('inline: editable in edit mode, no view hint', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await pump(
      t,
      PpForgeInput.inline(
        editing: true,
        controller: c,
        hint: 'Add a note',
        viewHint: 'Long-press to edit',
      ),
    );
    expect(find.text('Long-press to edit'), findsNothing);
    expect(find.text('Add a note'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'x');
    expect(c.text, 'x');
  });

  testWidgets('title: same box in view and edit', (t) async {
    final c = TextEditingController(text: 'กสิกร');
    addTearDown(c.dispose);
    await pump(t, PpForgeInput.title(editing: false, controller: c));
    final view = t.getSize(find.byType(PpForgeInput));
    await pump(t, PpForgeInput.title(editing: true, controller: c));
    expect(t.getSize(find.byType(PpForgeInput)), view);
  });

  testWidgets('search: ✕ appears with text and clears it', (t) async {
    String? last;
    await pump(
      t,
      PpForgeInput.search(hint: 'Search', onChanged: (v) => last = v),
    );
    expect(find.byType(IconButton), findsNothing);
    await t.enterText(find.byType(TextField), 'abc');
    await t.pump();
    expect(find.byType(IconButton), findsOneWidget);
    await t.tap(find.byType(IconButton));
    await t.pump();
    expect(last, '');
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('PpForgeSwitch toggles; PpForgeDivider draws a hairline', (
    t,
  ) async {
    var on = false;
    await pump(
      t,
      StatefulBuilder(
        builder: (context, set) => Column(
          children: [
            PpForgeSwitch(value: on, onChanged: (v) => set(() => on = v)),
            const PpForgeDivider.row(),
          ],
        ),
      ),
    );
    await t.tap(find.byType(Switch));
    await t.pump();
    expect(on, isTrue);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets(
    'PpForgeText: a role gives the theme style; maxLines ellipsises',
    (t) async {
      await pump(
        t,
        const PpForgeText('Hello', role: PpForgeTextRole.section, maxLines: 1),
      );
      final text = t.widget<Text>(find.text('Hello'));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontWeight, FontWeight.w600);
    },
  );
}
