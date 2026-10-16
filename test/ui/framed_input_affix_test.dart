import 'dart:ui' as ui;

import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A framed PpForgeInput with a label and a trailing affix (the password eye, a
/// suffix text): the label is drawn WHOLE (not cut by a parent's clip — a
/// SectionCard cell used to), the affix sits at the RIGHT edge and the text
/// area starts at the LEFT.
void main() {
  testWidgets(
    'framed + label + eye / suffix: label whole, affix at the right',
    (t) async {
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [sweetTheme.darkColors],
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                // Inside a SectionCard cell, like the Change password page.
                child: SectionCard(
                  first: true,
                  dividers: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          PpForgeInput(
                            label: 'Current password',
                            obscurable: true,
                          ),
                          const SizedBox(height: 16),
                          PpForgeInput(label: 'Amount', suffixText: 'THB'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      final fields = find.byType(PpForgeInput);
      final pw = t.getRect(fields.at(0));
      final eye = t.getRect(find.byType(IconButton).first);
      expect(
        t.getSize(fields.at(0)).height,
        t.getSize(fields.at(1)).height,
        reason: 'a field with the eye is as tall as one without',
      );
      expect(eye.right, greaterThan(pw.right - 24), reason: 'eye at the right');
      expect(eye.center.dx, greaterThan(pw.center.dx), reason: 'not centred');

      final suffix = t.getRect(find.text('THB'));
      final plain = t.getRect(fields.at(1));
      expect(
        suffix.right,
        greaterThan(plain.right - 24),
        reason: 'suffix right',
      );

      final input = t.getRect(find.byType(EditableText).first);
      expect(
        input.left,
        lessThan(pw.left + 24),
        reason: 'text area at the left',
      );

      // The label is not clipped: its top rows (above the frame's top border)
      // have painted pixels.
      final label = t.getRect(find.text('Current password'));
      final image = (await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return b.toImage(pixelRatio: 1);
      }))!;
      final data = (await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      final bg = Theme.of(
        t.element(find.byType(Scaffold)),
      ).scaffoldBackgroundColor;
      var lit = 0;
      for (var y = label.top.round(); y < pw.top.round(); y++) {
        for (var x = label.left.round(); x < label.right.round(); x++) {
          final o = (y * image.width + x) * 4;
          if ((data.getUint8(o) - (bg.r * 255).round()).abs() > 30) lit++;
        }
      }
      expect(lit, greaterThan(0), reason: 'the label above the frame is drawn');
    },
  );
}
