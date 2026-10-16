import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The editable-text indent rule (owner 2026-10-12), under a DetailStacked
/// label: an EDITABLE value's frame starts at the label and its text is
/// indented by the frame padding — in view AND edit, so nothing moves; a
/// read-only value (no frame) is flush with the label.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    ),
  );

  testWidgets('editable: the text is indented the same in view and edit', (
    t,
  ) async {
    final xs = <double>[];
    for (final editing in [false, true]) {
      final c = TextEditingController(text: 'note');
      addTearDown(c.dispose);
      await pump(
        t,
        DetailStacked(
          label: 'LABEL',
          child: PpForgeInput.inline(
            editing: editing,
            controller: c,
            onEnterEdit: () {},
          ),
        ),
      );
      final label = t.getTopLeft(find.text('LABEL')).dx;
      xs.add(t.getTopLeft(find.byType(EditableText)).dx - label);
      // The frame's left edge lines up with the label.
      expect(t.getTopLeft(find.byType(PpForgeInput)).dx, closeTo(label, 0.5));
    }
    expect(xs[0], closeTo(xs[1], 0.5), reason: 'nothing moves into edit');
    expect(xs[0], closeTo(16, 0.5));
  });

  testWidgets('read-only: no frame, the text is flush with the label', (
    t,
  ) async {
    final c = TextEditingController(text: 'note');
    addTearDown(c.dispose);
    await pump(
      t,
      DetailStacked(
        label: 'LABEL',
        child: PpForgeInput.inline(editing: false, controller: c),
      ),
    );
    final label = t.getTopLeft(find.text('LABEL')).dx;
    expect(t.getTopLeft(find.byType(EditableText)).dx, closeTo(label, 0.5));
  });

  testWidgets('outside DetailStacked: the inner padding stays', (t) async {
    final c = TextEditingController(text: 'x');
    addTearDown(c.dispose);
    await pump(t, PpForgeInput.inline(editing: true, controller: c));
    final box = t.getTopLeft(find.byType(PpForgeInput)).dx;
    final text = t.getTopLeft(find.byType(EditableText)).dx;
    expect(text - box, moreOrLessEquals(16, epsilon: 0.5));
  });
}
