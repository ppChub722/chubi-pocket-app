import 'package:pp_forge/pp_forge.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PpForgeInput.card as a form field (the change-password sheet): label ABOVE, an
/// underline, the eye at the right end, a helper under it, an error message.
void main() {
  inlineTests();
  Widget host(Widget child) => MaterialApp(
    theme: ThemeData(extensions: [sweetTheme.lightColors]),
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );

  testWidgets('card: obscurable eye at the right, helper, label above', (
    t,
  ) async {
    final c = TextEditingController(text: 'secret123');
    await t.pumpWidget(
      host(
        PpForgeInput.card(
          controller: c,
          label: 'New password',
          labelPlacement: PpForgeInputLabelPlacement.above,
          size: PpForgeInputSize.regular,
          obscurable: true,
          helper: 'At least 8 characters',
        ),
      ),
    );
    final field = t.getRect(find.byType(PpForgeInput));
    final eye = t.getRect(find.byType(IconButton).first);
    expect(
      eye.right,
      greaterThan(field.right - 24),
      reason: 'eye at the right',
    );
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('New password')).dy,
      lessThan(t.getTopLeft(find.byType(EditableText)).dy),
      reason: 'label above the text',
    );
    // The eye toggles the text.
    final before = t
        .widget<EditableText>(find.byType(EditableText))
        .obscureText;
    await t.tap(find.byType(IconButton).first);
    await t.pump();
    expect(
      t.widget<EditableText>(find.byType(EditableText)).obscureText,
      !before,
    );
  });

  testWidgets('card: errorText shows with the label above', (t) async {
    await t.pumpWidget(
      host(
        const PpForgeInput.card(
          label: 'Current password',
          labelPlacement: PpForgeInputLabelPlacement.above,
          size: PpForgeInputSize.regular,
          obscurable: true,
          errorText: 'Wrong password',
        ),
      ),
    );
    expect(find.text('Wrong password'), findsOneWidget);
    expect(find.text('Current password'), findsOneWidget);
  });
}

void inlineTests() {
  testWidgets('inline: obscurable eye inside the frame, helper, errorText', (
    t,
  ) async {
    final c = TextEditingController(text: 'secret123');
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PpForgeInput.inline(
                editing: true,
                controller: c,
                obscurable: true,
                helper: 'At least 8 characters',
              ),
            ),
          ),
        ),
      ),
    );
    final field = t.getRect(find.byType(PpForgeInput));
    expect(
      t.getRect(find.byType(IconButton).first).right,
      greaterThan(field.right - 24),
      reason: 'eye at the right, inside the frame',
    );
    expect(find.text('At least 8 characters'), findsOneWidget);
    expect(
      t.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    await t.tap(find.byType(IconButton).first);
    await t.pump();
    expect(
      t.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        home: Scaffold(
          body: PpForgeInput.inline(
            editing: true,
            controller: c,
            errorText: 'Wrong password',
          ),
        ),
      ),
    );
    expect(find.text('Wrong password'), findsOneWidget);
  });
}
