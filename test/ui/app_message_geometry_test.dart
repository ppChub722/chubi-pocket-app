import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// AppMessage (owner 2026-10-28): icon, text, action and close sit on one
/// centre line, with the same space above and below, in every tone (wide
/// enough that the text stays on one line; the two-line shapes are in
/// app_message_shapes_test.dart).
void main() {
  for (final tone in Tone.values) {
    for (final withAction in [true, false]) {
      testWidgets('${tone.name}, action: $withAction', (t) async {
        addTearDown(t.view.reset);
        await pumpGeometryRow(
          t,
          AppMessage(
            tone: tone,
            message: "Can't reach the server",
            actions: [
              if (withAction)
                AppMessageAction(label: 'Retry', onPressed: () {}),
            ],
            onClose: () {},
          ),
          width: 600,
          scale: 1,
        );
        final box = t.getRect(
          find
              .descendant(
                of: find.byType(AppMessage),
                matching: find.byType(Material),
              )
              .first,
        );
        final row = t.getRect(
          find
              .descendant(
                of: find.byType(AppMessage),
                matching: find.byType(Row),
              )
              .first,
        );
        final centres = [
          t.getRect(find.byIcon(AppMessage.iconOf(tone))).center.dy,
          t.getRect(find.text("Can't reach the server")).center.dy,
          if (withAction) t.getRect(find.text('Retry')).center.dy,
          t.getRect(find.byIcon(AppIcons.clear)).center.dy,
        ];
        for (final c in centres) {
          expect(c, closeTo(centres.first, 0.5));
        }
        expect(row.top - box.top, closeTo(box.bottom - row.bottom, 0.01));
        expect(row.top - box.top, greaterThanOrEqualTo(AppSpacing.sm));
      });
    }
  }
}
