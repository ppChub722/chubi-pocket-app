import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// AppMessage shapes (owner 2026-10-30): one line when the text fits beside at
/// most one action; otherwise icon + text + ✕ on the first text line and the
/// actions right-aligned under the text.
const _short = 'Wallet deleted';
const _long =
    'The wallet and its 24 transactions were deleted from this device and '
    'from the server, so they will not come back on the other phone';

AppMessage _message({
  required String text,
  required int actions,
  bool close = true,
}) => AppMessage(
  tone: Tone.danger,
  message: text,
  onClose: close ? () {} : null,
  actions: [
    if (actions >= 1) AppMessageAction(label: 'Undo', onPressed: () {}),
    if (actions == 2) AppMessageAction(label: 'View', onPressed: () {}),
  ],
);

void main() {
  for (final width in [320.0, 420.0]) {
    for (final scale in [1.0, 1.3]) {
      group('width $width, scale $scale', () {
        testWidgets('two actions: ✕ on the first text line, actions below', (
          t,
        ) async {
          addTearDown(t.view.reset);
          await pumpGeometryRow(
            t,
            _message(text: _short, actions: 2),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          final text = t.getRect(find.text(_short));
          final icon = t.getRect(find.byIcon(AppIcons.error));
          final close = t.getRect(find.byIcon(AppIcons.clear));
          // The text may wrap at a large scale: icon and ✕ sit on the first
          // line, which is never below the block centre.
          expect(icon.center.dy, closeTo(close.center.dy, 0.5));
          expect(close.center.dy, lessThanOrEqualTo(text.center.dy + 0.5));
          expect(close.center.dy, greaterThan(text.top));
          final undo = t.getRect(find.text('Undo'));
          final view = t.getRect(find.text('View'));
          expect(undo.top, greaterThanOrEqualTo(text.bottom));
          expect(view.center.dy, closeTo(undo.center.dy, 0.5));
          expect(view.left, greaterThan(undo.right));
          final box = t.getRect(
            find
                .descendant(
                  of: find.byType(AppMessage),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(view.right, lessThanOrEqualTo(box.right));
        });

        testWidgets('two actions, long text: no overflow, ✕ top-aligned', (
          t,
        ) async {
          addTearDown(t.view.reset);
          await pumpGeometryRow(
            t,
            _message(text: _long, actions: 2),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          final text = t.getRect(find.text(_long));
          final close = t.getRect(find.byIcon(AppIcons.clear));
          final icon = t.getRect(find.byIcon(AppIcons.error));
          // The first line is above the text block's centre.
          expect(close.center.dy, lessThan(text.center.dy));
          expect(icon.center.dy, closeTo(close.center.dy, 0.5));
          expect(
            t.getRect(find.text('Undo')).top,
            greaterThanOrEqualTo(text.bottom),
          );
        });

        testWidgets('one action, long text: two lines, actions below', (
          t,
        ) async {
          addTearDown(t.view.reset);
          await pumpGeometryRow(
            t,
            _message(text: _long, actions: 1),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          final text = t.getRect(find.text(_long));
          expect(
            t.getRect(find.text('Undo')).top,
            greaterThanOrEqualTo(text.bottom),
          );
          expect(
            t.getRect(find.byIcon(AppIcons.clear)).center.dy,
            lessThan(text.center.dy),
          );
        });

        testWidgets('no actions, long text: no overflow', (t) async {
          addTearDown(t.view.reset);
          await pumpGeometryRow(
            t,
            _message(text: _long, actions: 0),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
        });
      });
    }
  }

  testWidgets('one action, short text: stays on one centre line', (t) async {
    addTearDown(t.view.reset);
    await pumpGeometryRow(
      t,
      _message(text: _short, actions: 1),
      width: 420,
      scale: 1,
    );
    final centres = [
      t.getRect(find.byIcon(AppIcons.error)).center.dy,
      t.getRect(find.text(_short)).center.dy,
      t.getRect(find.text('Undo')).center.dy,
      t.getRect(find.byIcon(AppIcons.clear)).center.dy,
    ];
    for (final c in centres) {
      expect(c, closeTo(centres.first, 0.5));
    }
  });

  testWidgets('two actions, no ✕: actions under the text, right-aligned', (
    t,
  ) async {
    addTearDown(t.view.reset);
    await pumpGeometryRow(
      t,
      _message(text: _short, actions: 2, close: false),
      width: 320,
      scale: 1,
    );
    expect(t.takeException(), isNull);
    expect(find.byIcon(AppIcons.clear), findsNothing);
    expect(
      t.getRect(find.text('Undo')).top,
      greaterThanOrEqualTo(t.getRect(find.text(_short)).bottom),
    );
  });
}
