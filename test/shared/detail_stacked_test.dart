import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// DetailStacked's value text starts where its label starts (owner
/// 2026-10-11), in view AND edit mode; an InlineField elsewhere keeps its
/// inner padding.
void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(width: 400, child: child)),
    ),
  );

  for (final editing in [false, true]) {
    testWidgets('under a DetailStacked label (editing: $editing)', (t) async {
      final c = TextEditingController(text: 'note');
      addTearDown(c.dispose);
      await pump(
        t,
        DetailStacked(
          label: 'LABEL',
          child: InlineField(editing: editing, controller: c),
        ),
      );
      final label = t.getTopLeft(find.text('LABEL')).dx;
      final text = t.getTopLeft(find.byType(EditableText)).dx;
      expect(text, moreOrLessEquals(label, epsilon: 0.5));
    });
  }

  testWidgets('outside DetailStacked: the inner padding stays', (t) async {
    final c = TextEditingController(text: 'x');
    addTearDown(c.dispose);
    await pump(t, InlineField(editing: true, controller: c));
    final box = t.getTopLeft(find.byType(InlineField)).dx;
    final text = t.getTopLeft(find.byType(EditableText)).dx;
    expect(text - box, moreOrLessEquals(16, epsilon: 0.5));
  });
}
